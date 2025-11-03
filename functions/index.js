// functions/index.js

const functions = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");
const Anthropic = require("@anthropic-ai/sdk");

exports.generateNovelHttp = onRequest(
  {
    secrets: ["ANTHROPIC_API_KEY"],
    region: "asia-northeast3",
    cors: true,
    timeoutSeconds: 90,
  },
  async (req, res) => {
    // UTF-8 인코딩을 명시한 CORS 헤더 설정
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Accept");
    res.set("Content-Type", "application/json; charset=utf-8");

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ error: "Method not allowed" });
      return;
    }

    try {
      const apiKey = process.env.ANTHROPIC_API_KEY;
      if (!apiKey) {
        res.status(500).json({ error: "Anthropic API 키를 찾을 수 없습니다." });
        return;
      }

      const finalPrompt = req.body.prompt || req.body.data?.prompt;
      if (!finalPrompt) {
        res.status(400).json({ error: "프롬프트가 필요합니다." });
        return;
      }

      console.log("프롬프트 수신, 길이:", finalPrompt.length);

      const anthropic = new Anthropic({ apiKey: apiKey });
      
      const message = await anthropic.messages.create({
        model: "claude-sonnet-4-5-20250929",
        max_tokens: 4000,
        messages: [
          {
            role: "user",
            content: finalPrompt
          }
        ],
      });

      const result = message.content[0].text;
      console.log("Claude 응답 생성 완료, 길이:", result.length);

      // UTF-8 인코딩 보장
      const responseData = { result: result };
      const jsonString = JSON.stringify(responseData);
      
      // Buffer를 사용하여 UTF-8 인코딩 명시
      const buffer = Buffer.from(jsonString, 'utf-8');
      
      res.status(200)
         .set('Content-Type', 'application/json; charset=utf-8')
         .send(buffer);
         
    } catch (error) {
      console.error("오류 발생:", error);
      const errorResponse = { 
        error: error.message || "알 수 없는 오류",
        details: error.toString()
      };
      res.status(500)
         .set('Content-Type', 'application/json; charset=utf-8')
         .json(errorResponse);
    }
  }
);