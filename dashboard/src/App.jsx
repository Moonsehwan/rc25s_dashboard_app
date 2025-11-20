import React from "react";
import AGIChatPanel from "./components/AGIChatPanel";
import LogCard from "./components/LogCard";
import MemoryPanel from "./components/MemoryPanel";

export default function App() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-black text-white p-8 font-sans">
      <header className="mb-8 flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-extrabold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-500">
            AGI Control Center
          </h1>
          <p className="text-gray-400 text-sm mt-1">Project: 텍스트요약기</p>
        </div>
        <div className="flex gap-3">
          <div className="px-3 py-1 rounded-full bg-green-500/10 border border-green-500/30 text-green-400 text-xs flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            System Online
          </div>
        </div>
      </header>

      <div className="grid grid-cols-12 gap-6 h-[calc(100vh-140px)]">
        {/* Left Column: Chat (4) */}
        <div className="col-span-4 h-full">
          <AGIChatPanel project="텍스트요약기" />
        </div>

        {/* Middle Column: Memory (5) */}
        <div className="col-span-5 h-full">
          <MemoryPanel />
        </div>

        {/* Right Column: Logs (3) */}
        <div className="col-span-3 h-full">
          <LogCard />
        </div>
      </div>
    </div>
  );
}
