package com.zhizhi.module.ai.controller;

import com.zhizhi.common.BusinessException;
import com.zhizhi.common.Result;
import com.zhizhi.common.SecurityUtil;
import com.zhizhi.module.ai.entity.ChatMessage;
import com.zhizhi.module.ai.entity.ChatSession;
import com.zhizhi.module.ai.service.AiAssistService;
import com.zhizhi.module.ai.service.RagService;
import com.zhizhi.module.ai.service.VectorService;
import com.zhizhi.module.knowledge.entity.Knowledge;
import com.zhizhi.module.knowledge.service.KnowledgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

@Tag(name = "AI 智能功能")
@RestController
@RequestMapping("/ai")
@RequiredArgsConstructor
public class AiController {

    private final RagService ragService;
    private final VectorService vectorService;
    private final AiAssistService aiAssistService;
    private final KnowledgeService knowledgeService;

    // ==================== 对话会话 ====================

    @Operation(summary = "创建新对话会话")
    @PostMapping("/sessions")
    public Result<ChatSession> createSession(@RequestBody(required = false) Map<String, String> body) {
        String title = body != null ? body.get("title") : null;
        return Result.success(ragService.createSession(SecurityUtil.getCurrentUserId(), title));
    }

    @Operation(summary = "获取对话会话列表")
    @GetMapping("/sessions")
    public Result<List<ChatSession>> sessions() {
        return Result.success(ragService.getUserSessions(SecurityUtil.getCurrentUserId()));
    }

    @Operation(summary = "获取会话消息历史")
    @GetMapping("/sessions/{sessionId}/messages")
    public Result<List<ChatMessage>> messages(@PathVariable Long sessionId) {
        return Result.success(ragService.getMessages(sessionId));
    }

    @Operation(summary = "删除会话")
    @DeleteMapping("/sessions/{sessionId}")
    public Result<Void> deleteSession(@PathVariable Long sessionId) {
        ragService.deleteSession(sessionId, SecurityUtil.getCurrentUserId());
        return Result.success();
    }

    // ==================== RAG 流式问答 ====================

    @Operation(summary = "RAG 流式问答（SSE）")
    @GetMapping(value = "/chat", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<String> chat(
            @RequestParam Long sessionId,
            @RequestParam String question) {
        Long userId = SecurityUtil.getCurrentUserId();
        return ragService.chat(sessionId, question, userId);
    }

    // ==================== 向量化 ====================

    @Operation(summary = "单条知识向量化")
    @PostMapping("/vectorize/{knowledgeId}")
    public Result<Void> vectorize(@PathVariable Long knowledgeId) {
        Long userId = SecurityUtil.getCurrentUserId();
        Knowledge knowledge = knowledgeService.getById(knowledgeId);
        if (knowledge == null || !knowledge.getUserId().equals(userId)) {
            throw BusinessException.forbidden();
        }
        vectorService.vectorize(knowledge);
        return Result.success();
    }

    @Operation(summary = "批量向量化（所有未向量化条目）")
    @PostMapping("/vectorize-all")
    public Result<Void> vectorizeAll() {
        vectorService.vectorizeAll(SecurityUtil.getCurrentUserId());
        return Result.success();
    }

    // ==================== AI 辅助功能 ====================

    @Operation(summary = "AI 生成摘要")
    @PostMapping("/summary/{knowledgeId}")
    public Result<String> summary(@PathVariable Long knowledgeId) {
        Long userId = SecurityUtil.getCurrentUserId();
        Knowledge knowledge = knowledgeService.getById(knowledgeId);
        if (knowledge == null || !knowledge.getUserId().equals(userId)) {
            throw BusinessException.forbidden();
        }
        String summary = aiAssistService.generateSummary(knowledge.getTitle(), knowledge.getContent());
        knowledgeService.updateSummary(knowledgeId, userId, summary);
        return Result.success(summary);
    }

    @Operation(summary = "AI 推荐标签")
    @PostMapping("/recommend-tags/{knowledgeId}")
    public Result<List<String>> recommendTags(@PathVariable Long knowledgeId) {
        Long userId = SecurityUtil.getCurrentUserId();
        Knowledge knowledge = knowledgeService.getById(knowledgeId);
        if (knowledge == null || !knowledge.getUserId().equals(userId)) {
            throw BusinessException.forbidden();
        }
        String raw = aiAssistService.recommendTags(knowledge.getTitle(), knowledge.getContent());
        List<String> tags = Arrays.stream(raw.split("[,，]"))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
        return Result.success(tags);
    }
}
