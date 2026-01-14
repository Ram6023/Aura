export enum AssistantState {
  IDLE = 'IDLE',
  STANDBY = 'STANDBY',
  LISTENING = 'LISTENING',
  PROCESSING = 'PROCESSING',
  SPEAKING = 'SPEAKING',
  ERROR = 'ERROR'
}

export interface ChatMessage {
  id: string;
  sender: 'user' | 'aura' | 'system';
  text: string;
  timestamp: Date;
}

export interface SystemStatus {
  batteryLevel: number | null;
  isCharging: boolean;
  time: string;
  date: string;
  online: boolean;
}

export enum IntentType {
  SYSTEM_COMMAND = 'SYSTEM_COMMAND',
  INFORMATION_QUERY = 'INFORMATION_QUERY',
  WEB_ACTION = 'WEB_ACTION',
  CONVERSATION = 'CONVERSATION',
  UNKNOWN = 'UNKNOWN'
}

// Window augmentation for SpeechRecognition
declare global {
  interface Window {
    SpeechRecognition: any;
    webkitSpeechRecognition: any;
  }
}