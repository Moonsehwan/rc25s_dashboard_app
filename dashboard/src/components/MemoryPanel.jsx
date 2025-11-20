import React, { useState, useEffect } from "react";
import axios from "axios";

export default function MemoryPanel() {
    const [files, setFiles] = useState([]);
    const [selectedFile, setSelectedFile] = useState(null);
    const [content, setContent] = useState("");
    const [isEditing, setIsEditing] = useState(false);

    useEffect(() => {
        fetchFiles();
    }, []);

    const fetchFiles = async () => {
        try {
            const res = await axios.get("/agi/memory/list");
            setFiles(res.data.files);
        } catch (err) {
            console.error("Failed to fetch memory files", err);
        }
    };

    const handleSelectFile = async (filename) => {
        setSelectedFile(filename);
        try {
            const res = await axios.get(`/agi/memory/read?filename=${filename}`);
            setContent(res.data.content);
            setIsEditing(false);
        } catch (err) {
            console.error("Failed to read memory file", err);
        }
    };

    const handleSave = async () => {
        if (!selectedFile) return;
        try {
            await axios.post("/agi/memory/write", {
                path: selectedFile,
                content: content,
                overwrite: true
            });
            setIsEditing(false);
            fetchFiles();
        } catch (err) {
            console.error("Failed to save memory", err);
        }
    };

    return (
        <div className="bg-gray-800/50 backdrop-blur-md border border-gray-700 rounded-xl p-6 shadow-xl h-full flex flex-col">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                🧠 Long-Term Memory
                <span className="text-xs bg-purple-500/20 text-purple-300 px-2 py-1 rounded-full">Markdown</span>
            </h2>

            <div className="flex flex-1 gap-4 min-h-0">
                {/* File List */}
                <div className="w-1/3 border-r border-gray-700 pr-4 overflow-y-auto">
                    <div className="flex justify-between items-center mb-2">
                        <span className="text-gray-400 text-sm">Files</span>
                        <button
                            onClick={() => {
                                const name = prompt("New memory file name (e.g., plan.md):");
                                if (name) {
                                    setSelectedFile(name);
                                    setContent("# New Memory\n");
                                    setIsEditing(true);
                                }
                            }}
                            className="text-xs bg-blue-600 hover:bg-blue-500 text-white px-2 py-1 rounded transition"
                        >
                            + New
                        </button>
                    </div>
                    <ul className="space-y-1">
                        {files.map(f => (
                            <li
                                key={f}
                                onClick={() => handleSelectFile(f)}
                                className={`cursor-pointer px-3 py-2 rounded-lg text-sm transition-all ${selectedFile === f
                                        ? "bg-blue-600/30 text-blue-200 border border-blue-500/50"
                                        : "text-gray-400 hover:bg-gray-700/50 hover:text-gray-200"
                                    }`}
                            >
                                📄 {f}
                            </li>
                        ))}
                        {files.length === 0 && (
                            <li className="text-gray-600 text-xs italic p-2">No memories yet.</li>
                        )}
                    </ul>
                </div>

                {/* Editor/Viewer */}
                <div className="flex-1 flex flex-col min-h-0">
                    {selectedFile ? (
                        <>
                            <div className="flex justify-between items-center mb-2">
                                <span className="text-gray-300 font-mono text-sm">{selectedFile}</span>
                                <div className="flex gap-2">
                                    {isEditing ? (
                                        <>
                                            <button onClick={handleSave} className="text-xs bg-green-600 hover:bg-green-500 text-white px-3 py-1 rounded transition">Save</button>
                                            <button onClick={() => setIsEditing(false)} className="text-xs bg-gray-600 hover:bg-gray-500 text-white px-3 py-1 rounded transition">Cancel</button>
                                        </>
                                    ) : (
                                        <button onClick={() => setIsEditing(true)} className="text-xs bg-blue-600 hover:bg-blue-500 text-white px-3 py-1 rounded transition">Edit</button>
                                    )}
                                </div>
                            </div>
                            {isEditing ? (
                                <textarea
                                    className="flex-1 bg-gray-900/50 border border-gray-700 rounded-lg p-4 text-gray-200 font-mono text-sm resize-none focus:outline-none focus:border-blue-500/50 transition"
                                    value={content}
                                    onChange={(e) => setContent(e.target.value)}
                                />
                            ) : (
                                <div className="flex-1 bg-gray-900/30 border border-gray-700 rounded-lg p-4 overflow-y-auto prose prose-invert prose-sm max-w-none">
                                    <pre className="whitespace-pre-wrap font-sans text-gray-300">{content}</pre>
                                </div>
                            )}
                        </>
                    ) : (
                        <div className="flex-1 flex items-center justify-center text-gray-600">
                            Select a file to view memory
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}
