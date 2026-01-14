import React from 'react';
import { AssistantState } from '../types';

interface ArcReactorProps {
  state: AssistantState;
}

const ArcReactor: React.FC<ArcReactorProps> = ({ state }) => {
  const getColor = () => {
    switch (state) {
      case AssistantState.STANDBY: return 'border-cyan-900/50 shadow-[0_0_15px_#164e63]';
      case AssistantState.LISTENING: return 'border-cyan-400 shadow-[0_0_50px_#22d3ee] animate-pulse';
      case AssistantState.PROCESSING: return 'border-yellow-400 shadow-[0_0_50px_#facc15] animate-spin-slow';
      case AssistantState.SPEAKING: return 'border-cyan-400 shadow-[0_0_80px_#22d3ee]';
      case AssistantState.ERROR: return 'border-red-500 shadow-[0_0_50px_#ef4444]';
      default: return 'border-gray-800';
    }
  };

  const getInnerColor = () => {
    switch (state) {
      case AssistantState.STANDBY: return 'bg-cyan-950/20';
      case AssistantState.LISTENING: return 'bg-cyan-500/20';
      case AssistantState.PROCESSING: return 'bg-yellow-500/20';
      case AssistantState.SPEAKING: return 'bg-cyan-400/40';
      case AssistantState.ERROR: return 'bg-red-500/20';
      default: return 'bg-transparent';
    }
  };

  return (
    <div className="relative flex items-center justify-center">
      {/* Outer Ring */}
      <div className={`w-64 h-64 rounded-full border-4 border-dashed transition-all duration-500 ${getColor()} flex items-center justify-center relative`}>
        
        {/* Spinning Rings - Speed depends on state */}
        <div className={`absolute w-56 h-56 rounded-full border-2 border-cyan-500/30 ${state === AssistantState.PROCESSING ? 'animate-[spin_2s_linear_infinite]' : 'animate-[spin_10s_linear_infinite]'}`} />
        <div className={`absolute w-48 h-48 rounded-full border border-cyan-400/20 ${state === AssistantState.PROCESSING ? 'animate-[spin_2s_linear_infinite_reverse]' : 'animate-[spin_8s_linear_infinite_reverse]'}`} />
        
        {/* Core */}
        <div className={`w-32 h-32 rounded-full backdrop-blur-md transition-all duration-300 ${getInnerColor()} flex items-center justify-center border border-white/10`}>
          <div className="w-24 h-24 bg-white/5 rounded-full flex items-center justify-center">
            {/* Pulsing Core */}
            <div className={`w-16 h-16 rounded-full bg-white transition-all duration-200 ${
              state === AssistantState.SPEAKING ? 'scale-110 opacity-80 animate-pulse' : 
              state === AssistantState.STANDBY ? 'scale-90 opacity-10' :
              'scale-100 opacity-20'
            }`} />
          </div>
        </div>
      </div>
      
      {/* Status Text Label */}
      <div className="absolute -bottom-12 font-sci-fi text-cyan-400 tracking-widest text-sm uppercase">
        {state === AssistantState.STANDBY ? 'STANDBY' : state} MODE
      </div>
    </div>
  );
};

export default ArcReactor;