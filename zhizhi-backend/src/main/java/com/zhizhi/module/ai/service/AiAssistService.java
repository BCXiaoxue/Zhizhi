package com.zhizhi.module.ai.service;

import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AiAssistService {

    private final ChatClient chatClient;

    public String generateSummary(String title, String content) {
        String text = content != null && content.length() > 2000
                ? content.substring(0, 2000) : content;
        return chatClient.prompt()
                .user("""
                        请为以下知识条目生成一段简洁的摘要（100字以内），直接输出摘要内容，不要加前缀。

                        标题：%s
                        内容：%s
                        """.formatted(title, text))
                .call()
                .content();
    }

    public String recommendTags(String title, String content) {
        String text = content != null && content.length() > 1000
                ? content.substring(0, 1000) : content;
        return chatClient.prompt()
                .user("""
                        请为以下知识条目推荐3到5个标签，用英文逗号分隔，直接输出标签，不要解释。
                        例如：Java,Spring Boot,后端开发

                        标题：%s
                        内容：%s
                        """.formatted(title, text))
                .call()
                .content();
    }
}
