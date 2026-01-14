import React, { useEffect, useState } from 'react';
import { SystemStatus } from '../types';
import { Battery, Wifi, Cpu, Clock, Calendar } from 'lucide-react';

interface SystemStatsProps {
  status: SystemStatus;
}

const SystemStats: React.FC<SystemStatsProps> = ({ status }) => {
  const [cpuUsage, setCpuUsage] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCpuUsage(Math.floor(Math.random() * 30) + 10); // Simulate CPU usage
    }, 2000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 w-full">
      <StatCard 
        icon={<Clock size={18} />} 
        label="TIME" 
        value={status.time} 
      />
      <StatCard 
        icon={<Calendar size={18} />} 
        label="DATE" 
        value={status.date} 
      />
      <StatCard 
        icon={<Battery size={18} />} 
        label="POWER" 
        value={status.batteryLevel ? `${(status.batteryLevel * 100).toFixed(0)}%` : '100%'} 
        subValue={status.isCharging ? 'CHARGING' : 'DISCHARGING'}
      />
      <StatCard 
        icon={<Cpu size={18} />} 
        label="CPU LOAD" 
        value={`${cpuUsage}%`} 
        subValue="STABLE"
      />
    </div>
  );
};

const StatCard: React.FC<{icon: React.ReactNode, label: string, value: string, subValue?: string}> = ({ icon, label, value, subValue }) => (
  <div className="bg-cyan-900/10 border border-cyan-800/30 p-3 rounded flex items-center gap-3">
    <div className="p-2 bg-cyan-900/30 rounded text-cyan-400">
      {icon}
    </div>
    <div>
      <div className="text-[10px] text-gray-500 tracking-widest">{label}</div>
      <div className="text-sm font-bold text-gray-200 font-sci-fi">{value}</div>
      {subValue && <div className="text-[9px] text-cyan-600">{subValue}</div>}
    </div>
  </div>
);

export default SystemStats;