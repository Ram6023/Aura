import { useState, useEffect, useCallback, useRef } from 'react';
import { AssistantState, ChatMessage, SystemStatus } from '../types';
import { WAKE_WORD } from '../constants';
import { generateResponse } from '../services/geminiService';

export const useJarvis = () => {
  const [state, setState] = useState<AssistantState>(AssistantState.IDLE);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [transcript, setTranscript] = useState('');
  const [systemStatus, setSystemStatus] = useState<SystemStatus>({
    batteryLevel: 1,
    isCharging: true,
    time: '',
    date: '',
    online: true
  });

  const recognitionRef = useRef<any>(null);
  const silenceTimerRef = useRef<NodeJS.Timeout | null>(null);
  const isSpeakingRef = useRef(false);
  
  // Ref to track state inside the closure of SpeechRecognition callback
  const stateRef = useRef<AssistantState>(AssistantState.IDLE);
  
  // Confidence threshold to filter out background noise
  const CONFIDENCE_THRESHOLD = 0.5;

  // Sync state ref
  useEffect(() => {
    stateRef.current = state;
  }, [state]);

  // --- TTS ---
  const speak = useCallback((text: string) => {
    if (isSpeakingRef.current) window.speechSynthesis.cancel();

    setState(AssistantState.SPEAKING);
    isSpeakingRef.current = true;
    
    // Clean text for speech (remove some markdown symbols if any)
    const cleanText = text.replace(/[*#]/g, '');

    const utterance = new SpeechSynthesisUtterance(cleanText);
    utterance.rate = 1.0;
    utterance.pitch = 1.05; 
    utterance.volume = 1.0;
    
    // Dynamic Voice Selection based on User's Language
    const voices = window.speechSynthesis.getVoices();
    const userLang = navigator.language || 'en-US';
    
    // 1. Try to find a voice that exactly matches the language
    let preferredVoice = voices.find(v => v.lang === userLang);
    
    // 2. If not, try to find a voice that matches the language code (e.g., 'en' in 'en-US')
    if (!preferredVoice) {
        preferredVoice = voices.find(v => v.lang.startsWith(userLang.split('-')[0]));
    }

    // 3. Fallback to specific "Aura-like" voices if in English, otherwise default
    if (!preferredVoice && userLang.startsWith('en')) {
        preferredVoice = voices.find(v => 
            v.name.includes('Google US English') || 
            v.name.includes('Samantha') ||
            v.name.includes('Microsoft Zira')
        );
    }

    if (preferredVoice) utterance.voice = preferredVoice;

    const handleEnd = () => {
        isSpeakingRef.current = false;
        // Return to STANDBY after speaking
        setState(AssistantState.STANDBY);
        startListening(); 
    };

    utterance.onend = handleEnd;
    utterance.onerror = handleEnd;

    window.speechSynthesis.speak(utterance);
  }, []);

  // --- Helper to add messages ---
  const addMessage = (sender: 'user' | 'aura' | 'system', text: string) => {
    setMessages(prev => [...prev, {
      id: Date.now().toString(),
      sender,
      text,
      timestamp: new Date()
    }]);
  };

  // --- Command Processor ---
  const processCommand = async (command: string) => {
    setState(AssistantState.PROCESSING);
    
    const lowerCmd = command.toLowerCase();

    // 1. System Commands (Basic English Triggers for functionality)
    if (lowerCmd.includes('open google')) {
      addMessage('system', 'Opening Google Chrome...');
      speak("Opening Google search.");
      window.open('https://google.com', '_blank');
      return;
    }
    
    if (lowerCmd.includes('open youtube')) {
      addMessage('system', 'Opening YouTube...');
      speak("Launching YouTube.");
      window.open('https://youtube.com', '_blank');
      return;
    }

    if (lowerCmd.includes('time') && lowerCmd.includes('what')) {
      const timeStr = new Date().toLocaleTimeString();
      addMessage('aura', `System Time: ${timeStr}`);
      // Let LLM handle the spoken response for natural language
    } else if (lowerCmd.includes('clear console') || lowerCmd.includes('clear log')) {
        setMessages([]);
        speak("Console cleared.");
        return;
    }

    if (lowerCmd.includes('shutdown') || lowerCmd.includes('power off')) {
        addMessage('system', 'Initiating Shutdown Sequence...');
        speak("Shutting down system.");
        setTimeout(() => {
           document.body.innerHTML = '<div style="display:flex;justify-content:center;align-items:center;height:100vh;background:black;color:white;font-family:monospace;">SYSTEM OFFLINE</div>';
        }, 3000);
        return;
    }

    // 2. AI Queries (Gemini)
    try {
        const historyText = messages.map(m => `${m.sender}: ${m.text}`);
        const response = await generateResponse(command, historyText);
        addMessage('aura', response);
        speak(response);
    } catch (e) {
        addMessage('system', 'Error connecting to AI Network.');
        speak("I am unable to connect to the network.");
        setState(AssistantState.ERROR);
        setTimeout(() => setState(AssistantState.STANDBY), 3000);
    }
  };

  // --- STT Setup ---
  const startListening = useCallback(() => {
    if (!('SpeechRecognition' in window || 'webkitSpeechRecognition' in window)) {
        addMessage('system', 'Speech Recognition not supported in this browser.');
        return;
    }

    // Prevent multiple instances
    if (recognitionRef.current) {
        try { recognitionRef.current.stop(); } catch(e) {}
    }

    try {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        const recognition = new SpeechRecognition();
        
        // Optimize parameters for continuous listening and noise handling
        recognition.continuous = true; 
        recognition.interimResults = true;
        recognition.maxAlternatives = 1;
        
        // Dynamic Language Detection: Use the user's browser language
        recognition.lang = navigator.language || 'en-US';

        recognition.onstart = () => {
             // Only set to STANDBY if we were IDLE
             if (stateRef.current === AssistantState.IDLE) {
                 setState(AssistantState.STANDBY);
             }
        };

        recognition.onresult = (event: any) => {
            if (isSpeakingRef.current) return;

            const current = event.resultIndex;
            const resultObj = event.results[current];
            const result = resultObj[0];
            const transcriptRaw = result.transcript;
            const transcriptLower = transcriptRaw.toLowerCase().trim();
            const isFinal = resultObj.isFinal;
            const confidence = result.confidence;
            
            // STATE: STANDBY (Waiting for "Hey Aura")
            if (stateRef.current === AssistantState.STANDBY) {
                 // Check for Wake Word
                 // We look at interim results for speed, but rely on string matching
                 const isWakeWord = transcriptLower.includes(WAKE_WORD) || transcriptLower.startsWith("aura");
                 
                 if (isWakeWord) {
                     setState(AssistantState.LISTENING);
                     
                     // Check if there is a command immediately following the wake word
                     // e.g. "Hey Aura what is the time"
                     const parts = transcriptLower.split(WAKE_WORD);
                     let commandPart = parts.length > 1 ? parts[1].trim() : "";
                     
                     if (!commandPart && transcriptLower.startsWith("aura")) {
                         commandPart = transcriptLower.substring(4).trim();
                     }
                     
                     // If we have a substantial command immediately, process it
                     if (commandPart.length > 2) {
                         setTranscript(commandPart);
                         
                         // If it's final, process immediately. 
                         // If it's interim, we wait for the rest or silence.
                         if (isFinal) {
                             if (confidence > CONFIDENCE_THRESHOLD || confidence === 0) {
                                 // Stop recognition to reset stream
                                 recognition.stop();
                                 addMessage('user', commandPart);
                                 processCommand(commandPart);
                             }
                         } else {
                             // Reset silence timer to wait for more speech
                             if (silenceTimerRef.current) clearTimeout(silenceTimerRef.current);
                             silenceTimerRef.current = setTimeout(() => {
                                 recognition.stop();
                                 addMessage('user', commandPart);
                                 processCommand(commandPart);
                             }, 2500);
                         }
                     } else {
                         setTranscript(""); // Wake word detected, waiting for command
                     }
                 }
            } 
            // STATE: LISTENING (Capturing Command)
            else if (stateRef.current === AssistantState.LISTENING) {
                let commandText = transcriptLower;
                // Strip wake word if repeated in the stream
                if (commandText.includes(WAKE_WORD)) {
                    commandText = commandText.split(WAKE_WORD).pop()?.trim() || "";
                } else if (commandText.startsWith("aura ")) {
                     commandText = commandText.substring(5).trim();
                }
                
                setTranscript(commandText);

                // Debounce silence
                if (silenceTimerRef.current) clearTimeout(silenceTimerRef.current);

                if (isFinal) {
                    // Filter out low confidence noise
                    // Note: Some browsers return 0 confidence for everything, so we allow 0 as well if isFinal is true
                    if (confidence > 0 && confidence < CONFIDENCE_THRESHOLD) {
                        console.log("Ignored low confidence speech:", commandText, confidence);
                        return;
                    }

                    if (commandText.length > 0) {
                        recognition.stop();
                        addMessage('user', commandText);
                        processCommand(commandText);
                    }
                } else {
                    // Interim results - wait for silence
                    silenceTimerRef.current = setTimeout(() => {
                        if (commandText.length > 0) {
                            recognition.stop();
                            addMessage('user', commandText);
                            processCommand(commandText);
                        }
                    }, 2500); // Increased silence timeout for better pause handling
                }
            }
        };

        recognition.onend = () => {
            // Auto-restart loop
            if (!isSpeakingRef.current && 
                stateRef.current !== AssistantState.PROCESSING && 
                stateRef.current !== AssistantState.IDLE) {
                try {
                    recognition.start();
                    // Ensure we reset to STANDBY if we were just listening but stream ended
                    if (stateRef.current === AssistantState.LISTENING) {
                         setState(AssistantState.STANDBY);
                         setTranscript("");
                    }
                } catch (e) {
                    // Ignore start errors
                }
            }
        };

        recognition.onerror = (event: any) => {
            if (event.error !== 'no-speech') {
                console.error("Speech Error", event.error);
            }
        };

        recognitionRef.current = recognition;
        recognition.start();

    } catch (e) {
        console.error("Speech Init Error:", e);
    }
  }, [speak]); // Dependencies

  const stopListening = () => {
    if (recognitionRef.current) {
        recognitionRef.current.stop();
    }
    setState(AssistantState.IDLE);
    stateRef.current = AssistantState.IDLE;
  };

  // --- System Stats Updater ---
  useEffect(() => {
    const updateTime = () => {
        const now = new Date();
        setSystemStatus(prev => ({
            ...prev,
            time: now.toLocaleTimeString(),
            date: now.toLocaleDateString(),
            online: navigator.onLine
        }));
    };

    const timer = setInterval(updateTime, 1000);
    
    if ('getBattery' in navigator) {
        (navigator as any).getBattery().then((battery: any) => {
            setSystemStatus(prev => ({ ...prev, batteryLevel: battery.level, isCharging: battery.charging }));
            battery.addEventListener('levelchange', () => {
                 setSystemStatus(prev => ({ ...prev, batteryLevel: battery.level }));
            });
        });
    }

    return () => clearInterval(timer);
  }, []);

  return {
    state,
    transcript,
    messages,
    systemStatus,
    startListening,
    stopListening,
    speak
  };
};