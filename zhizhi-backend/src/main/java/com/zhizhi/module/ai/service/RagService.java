package com.zhizhi.module.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.zhizhi.module.ai.entity.ChatMessage;
import com.zhizhi.module.ai.entity.ChatSession;
import com.zhizhi.module.ai.mapper.ChatMessageMapper;
import com.zhizhi.module.ai.mapper.ChatSessionMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.document.Document;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class RagService {

    private final ChatClient chatClient;
    private final VectorService vectorService;
    private final ChatSessionMapper chatSessionMapper;
    private final ChatMessageMapper chatMessageMapper;

    private static final int MAX_HISTORY_TURNS = 5;

    public Flux<String> chat(Long sessionId, String question, Long userId) {
        List<Document> docs = vectorService.search(question, 3);
        String context = docs.stream()
                .map(Document::getText)
                .collect(Collectors.joining("\n---\n"));

        List<String> sourceIds = docs.stream()
                .map(d -> d.getMetadata().getOrDefault("knowledgeId", "").toString())
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toList());

        String systemPrompt;
        if (context.isEmpty()) {
            systemPrompt = "你是智知助手，请根据你的知识回答用户问题。如果不确定，请坦诚说明。";
        } else {
            systemPrompt = """
                    你是智知助手，请严格基于以下知识库内容回答用户问题，不要捏造信息。
                    如果知识库中没有相关内容，请如实告知用户"知识库中暂无相关内容"。

                    知识库内容：
                    %s
                    """.formatted(context);
        }

        List<Message> messages = buildHistory(sessionId);
        saveMessage(sessionId, "user", question, null);

        StringBuilder fullResponse = new StringBuilder();
        final List<String> finalSourceIds = sourceIds;

        return chatClient.prompt()
                .system(systemPrompt)
                .messages(messages)
                .user(question)
                .stream()
                .content()
                .doOnNext(fullResponse::append)
                .doOnComplete(() -> {
                    String sourcesJson = finalSourceIds.isEmpty() ? null
                            : "[" + finalSourceIds.stream().map(id -> "\"" + id + "\"").collect(Collectors.joining(",")) + "]";
                    saveMessage(sessionId, "assistant", fullResponse.toString(), sourcesJson);
                });
    }

    public ChatSession createSession(Long userId, String title) {
        ChatSession session = new ChatSession();
        session.setUserId(userId);
        session.setTitle(title != null ? title : "新对话");
        chatSessionMapper.insert(session);
        return session;
    }

    public List<ChatSession> getUserSessions(Long userId) {
        return chatSessionMapper.selectList(new LambdaQueryWrapper<ChatSession>()
                .eq(ChatSession::getUserId, userId)
                .orderByDesc(ChatSession::getUpdatedAt));
    }

    public List<ChatMessage> getMessages(Long sessionId) {
        return chatMessageMapper.selectList(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getSessionId, sessionId)
                .orderByAsc(ChatMessage::getCreatedAt));
    }

    public void deleteSession(Long sessionId, Long userId) {
        ChatSession session = chatSessionMapper.selectById(sessionId);
        if (session != null && session.getUserId().equals(userId)) {
            chatSessionMapper.deleteById(sessionId);
        }
    }

    private List<Message> buildHistory(Long sessionId) {
        List<ChatMessage> history = chatMessageMapper.selectList(
                new LambdaQueryWrapper<ChatMessage>()
                        .eq(ChatMessage::getSessionId, sessionId)
                        .orderByAsc(ChatMessage::getCreatedAt)
                        .last("LIMIT " + (MAX_HISTORY_TURNS * 2))
        );
        List<Message> messages = new ArrayList<>();
        for (ChatMessage msg : history) {
            if ("user".equals(msg.getRole())) {
                messages.add(new UserMessage(msg.getContent()));
            } else {
                messages.add(new AssistantMessage(msg.getContent()));
            }
        }
        return messages;
    }

    private void saveMessage(Long sessionId, String role, String content, String sources) {
        ChatMessage msg = new ChatMessage();
        msg.setSessionId(sessionId);
        msg.setRole(role);
        msg.setContent(content);
        msg.setSources(sources);
        chatMessageMapper.insert(msg);
    }
}
