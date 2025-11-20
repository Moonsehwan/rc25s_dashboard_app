import axios from "axios";

const AGI_SERVER = "https://api.mcpvibe.org/agi"; // 실제 AGI 서버 주소로 설정 (Nginx proxy path)
const OPENAI_API_KEY = process.env.OPENAI_API_KEY; // GPT 호출용 키

export async function agiGatewayChat(project, userMessage) {
  try {
    // 1. 컨텍스트 가져오기
    const context = await axios.get(`${AGI_SERVER}/context/${project}`);

    // 2. 실패 원인 가져오기
    const failRes = await axios.get(`${AGI_SERVER}/loop/failure-insight`, {
      params: { project },
    });
    const failReasons = failRes.data.recent_failures.map(
      (f) => `- ${f.reason}`
    ).join("\n");

    // 3. system_prompt 구성
    const systemPrompt = `당신은 프로젝트 '${project}'의 AGI입니다.\n` +
      context.data.system_prompt +
      `\n최근 실패 원인:\n${failReasons}\n` +
      `사용자 질문: ${userMessage}`;

    // 4. GPT 응답 요청
    const gptRes = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model: "gpt-4",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userMessage }
        ]
      },
      {
        headers: {
          Authorization: `Bearer ${OPENAI_API_KEY}`,
          "Content-Type": "application/json"
        }
      }
    );

    const assistantReply = gptRes.data.choices[0].message.content;

    // 5. 대화 기록 저장
    await axios.post(`${AGI_SERVER}/log-dialogue`, {
      project,
      user_message: userMessage,
      assistant_reply: assistantReply
    });

    return assistantReply;
  } catch (error) {
    console.error("AGI Gateway Error:", error);
    return "AGI 게이트웨이 오류가 발생했습니다.";
  }
}