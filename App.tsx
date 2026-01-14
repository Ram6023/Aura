import React, { useState } from 'react';
import { Play, Mic, MicOff, Power, ShieldAlert } from 'lucide-react';
import ArcReactor from './components/ArcReactor';
import Terminal from './components/Terminal';
import SystemStats from './components/SystemStats';
import { useJarvis } from './hooks/useJarvis';
import { AssistantState } from './types';

function App() {
  const { 
    state, 
    transcript, 
    messages, 
    systemStatus, 
    startListening, 
    stopListening 
  } = useJarvis();

  const [initialized, setInitialized] = useState(false);

  const handleInit = () => {
    setInitialized(true);
    startListening();
  };

  if (!initialized) {
    return (
      <div className="min-h-screen bg-black flex flex-col items-center justify-center p-8 relative overflow-hidden">
        <div className="absolute inset-0 bg-[url('https://picsum.photos/1920/1080?grayscale&blur=2')] opacity-20 bg-cover bg-center" />
        <div className="z-10 text-center space-y-8 max-w-lg w-full">
          <h1 className="text-6xl font-sci-fi text-cyan-400 glow-text mb-4">AURA</h1>
          <p className="text-cyan-200/70 font-mono">
            ADVANCED USER RESPONSIVE AUTOMATION
          </p>
          
          <div className="border border-cyan-800/50 bg-cyan-950/30 p-6 rounded-lg backdrop-blur-sm">
             <h3 className="text-cyan-400 font-bold mb-2 flex items-center justify-center gap-2">
               <ShieldAlert size={18} /> SECURITY CHECK
             </h3>
             <p className="text-sm text-gray-400 mb-4">
               Microphone access and API Key validation required for initialization.
             </p>
             <button 
               onClick={handleInit}
               className="group relative px-8 py-3 bg-cyan-900/40 hover:bg-cyan-500/20 border border-cyan-500/50 rounded-none transition-all duration-300 w-full overflow-hidden"
             >
               <span className="absolute w-0 h-full bg-cyan-500/20 left-0 top-0 transition-all duration-300 group-hover:w-full"></span>
               <span className="relative font-sci-fi tracking-widest text-cyan-300 group-hover:text-cyan-100 flex items-center justify-center gap-2">
                 <Power size={18} /> INITIALIZE SYSTEM
               </span>
             </button>
          </div>
          <p className="text-xs text-gray-600 font-mono">v4.0.0 // STANDBY</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#050505] text-cyan-100 p-4 md:p-8 flex flex-col relative overflow-hidden">
      {/* Background Grids */}
      <div className="absolute inset-0 pointer-events-none" 
           style={{
             backgroundImage: `linear-gradient(rgba(6,182,212,0.05) 1px, transparent 1px), linear-gradient(90deg, rgba(6,182,212,0.05) 1px, transparent 1px)`,
             backgroundSize: '40px 40px'
           }} 
      />

      {/* Header Stats */}
      <header className="relative z-10 mb-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-cyan-900/30 pb-4">
        <div>
          <h1 className="text-2xl font-sci-fi text-cyan-400 glow-text">AURA</h1>
          <p className="text-[10px] text-cyan-600 tracking-[0.3em] font-mono">ADVANCED VIRTUAL ASSISTANT</p>
        </div>
        <div className="w-full md:w-auto">
          <SystemStats status={systemStatus} />
        </div>
      </header>

      {/* Main Content Area */}
      <main className="relative z-10 flex-1 grid grid-cols-1 lg:grid-cols-12 gap-6 h-[calc(100vh-200px)]">
        
        {/* Left Panel: Visualizer & Live Transcript */}
        <div className="lg:col-span-5 flex flex-col items-center justify-center bg-cyan-950/10 border border-cyan-900/30 rounded-2xl p-8 relative overflow-hidden">
          <div className="absolute top-4 left-4 text-xs font-mono text-cyan-700">VISUAL_FEED_01</div>
          
          <div className="mb-12 scale-125">
            <ArcReactor state={state} />
          </div>

          {/* Live Transcript Overlay */}
          <div className="w-full max-w-md min-h-[60px] text-center space-y-2">
            {state === AssistantState.STANDBY && (
               <div className="text-cyan-700/50 text-xs font-mono tracking-widest">
                  SAY "HEY AURA" TO ACTIVATE
               </div>
            )}
            {state === AssistantState.LISTENING && (
              <div className="text-cyan-400/80 animate-pulse text-sm font-mono tracking-wider">
                LISTENING...
              </div>
            )}
            {transcript && (
              <div className="text-lg font-light text-white glow-text">
                "{transcript}"
              </div>
            )}
          </div>
          
          {/* Controls */}
          <div className="mt-8 flex gap-4">
            <button 
              onClick={state !== AssistantState.IDLE ? stopListening : startListening}
              className={`p-4 rounded-full border transition-all duration-300 ${
                state !== AssistantState.IDLE
                  ? 'bg-red-500/20 border-red-500/50 text-red-400 hover:bg-red-500/30' 
                  : 'bg-cyan-500/20 border-cyan-500/50 text-cyan-400 hover:bg-cyan-500/30'
              }`}
            >
              {state !== AssistantState.IDLE ? <MicOff size={24} /> : <Mic size={24} />}
            </button>
          </div>
        </div>

        {/* Right Panel: Terminal / Logs */}
        <div className="lg:col-span-7 h-full">
           <Terminal messages={messages} />
        </div>

      </main>
      
      {/* Footer */}
      <footer className="relative z-10 mt-4 text-center">
        <div className="inline-flex items-center gap-2 text-[10px] text-cyan-800 font-mono border-t border-cyan-900/30 pt-2 px-4">
          <div className={`w-2 h-2 rounded-full ${systemStatus.online ? 'bg-green-500' : 'bg-red-500'}`} />
          SERVER CONNECTION: {systemStatus.online ? 'STABLE' : 'OFFLINE'} | LATENCY: 24ms | MEMORY: 64TB
        </div>
      </footer>
    </div>
  );
}

export default App;