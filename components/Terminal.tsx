import React, { useEffect, useRef } from 'react';
import { ChatMessage } from '../types';
import { Terminal as TerminalIcon } from 'lucide-react';

interface TerminalProps {
  messages: ChatMessage[];
}

const Terminal: React.FC<TerminalProps> = ({ messages }) => {
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="h-full flex flex-col font-mono text-sm border border-cyan-900/50 bg-black/40 rounded-lg overflow-hidden glow-box">
      <div className="flex items-center gap-2 p-2 border-b border-cyan-900/50 bg-cyan-900/20">
        <TerminalIcon size={14} className="text-cyan-400" />
        <span className="text-xs text-cyan-400 uppercase tracking-wider">System Logs</span>
      </div>
      
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.map((msg) => (
          <div key={msg.id} className={`flex flex-col ${msg.sender === 'user' ? 'items-end' : 'items-start'}`}>
            <span className={`text-[10px] mb-1 uppercase tracking-widest ${
              msg.sender === 'user' ? 'text-gray-500' : 
              msg.sender === 'aura' ? 'text-cyan-400' : 'text-yellow-500'
            }`}>
              {msg.sender === 'aura' ? 'AURA' : msg.sender}
            </span>
            <div className={`max-w-[80%] p-2 rounded border ${
              msg.sender === 'user' 
                ? 'border-gray-700 bg-gray-900/50 text-gray-300' 
                : msg.sender === 'aura'
                  ? 'border-cyan-800 bg-cyan-900/20 text-cyan-100'
                  : 'border-yellow-800 bg-yellow-900/20 text-yellow-100'
            }`}>
              {msg.text}
            </div>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>
    </div>
  );
};

export default Terminal;