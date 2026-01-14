import { GoogleGenAI } from "@google/genai";
import { SYSTEM_PROMPT, GEMINI_MODEL } from '../constants';

let aiInstance: GoogleGenAI | null = null;

const getAI = () => {
  if (!aiInstance) {
    if (!process.env.API_KEY) {
      console.warn("API Key is missing!");
      throw new Error("API Key is missing");
    }
    aiInstance = new GoogleGenAI({ apiKey: process.env.API_KEY });
  }
  return aiInstance;
};

export const generateResponse = async (prompt: string, history: string[]): Promise<string> => {
  try {
    const ai = getAI();
    
    // Construct a context-aware prompt
    const conversationContext = history.slice(-5).join('\n');
    const fullPrompt = `${SYSTEM_PROMPT}\n\nRecent Conversation:\n${conversationContext}\n\nUser: ${prompt}\nJ.A.R.V.I.S.:`;

    const response = await ai.models.generateContent({
      model: GEMINI_MODEL,
      contents: fullPrompt,
    });

    return response.text || "I apologize, sir, but I'm having trouble processing that request.";
  } catch (error) {
    console.error("Gemini API Error:", error);
    return "I seem to have lost connection to the main server, sir. Please check the API configuration.";
  }
};
