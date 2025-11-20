import { useState } from "react";
import { agiGatewayChat } from "./gateway-router";

export function useAGIChat(project) {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(false);

  const sendMessage = async (userMessage) => {
    setLoading(true);
    const newMessage = { role: "user", content: userMessage };
    setMessages((prev) => [...prev, newMessage]);

    try {
      const reply = await agiGatewayChat(project, userMessage);
      setMessages((prev) => [...prev, { role: "assistant", content: reply }]);
    } catch (error) {
      setMessages((prev) => [...prev, { role: "assistant", content: "오류 발생" }]);
    }

    setLoading(false);
  };

  return {
    messages,
    loading,
    sendMessage,
  };
}