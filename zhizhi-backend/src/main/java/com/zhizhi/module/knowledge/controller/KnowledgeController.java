package com.zhizhi.module.knowledge.controller;

import com.zhizhi.common.PageResult;
import com.zhizhi.common.Result;
import com.zhizhi.common.SecurityUtil;
import com.zhizhi.module.knowledge.dto.KnowledgeRequest;
import com.zhizhi.module.knowledge.dto.KnowledgeVO;
import com.zhizhi.module.knowledge.service.KnowledgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;

@Tag(name = "知识管理")
@RestController
@RequestMapping("/knowledge")
@RequiredArgsConstructor
public class KnowledgeController {

    private final KnowledgeService knowledgeService;

    @Operation(summary = "分页查询知识列表")
    @GetMapping
    public Result<PageResult<KnowledgeVO>> list(
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "10") long size,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long tagId) {
        Long userId = SecurityUtil.isAdmin() ? null : SecurityUtil.getCurrentUserId();
        return Result.success(knowledgeService.page(userId, categoryId, tagId, current, size));
    }

    @Operation(summary = "全文搜索")
    @GetMapping("/search")
    public Result<List<KnowledgeVO>> search(@RequestParam String q) {
        Long userId = SecurityUtil.isAdmin() ? null : SecurityUtil.getCurrentUserId();
        return Result.success(knowledgeService.search(userId, q));
    }

    @Operation(summary = "获取知识详情")
    @GetMapping("/{id}")
    public Result<KnowledgeVO> detail(@PathVariable Long id) {
        return Result.success(knowledgeService.getDetailVO(id, SecurityUtil.getCurrentUserId()));
    }

    @Operation(summary = "创建知识条目")
    @PostMapping
    public Result<KnowledgeVO> create(@Valid @RequestBody KnowledgeRequest req) {
        return Result.success(knowledgeService.create(SecurityUtil.getCurrentUserId(), req));
    }

    @Operation(summary = "更新知识条目")
    @PutMapping("/{id}")
    public Result<KnowledgeVO> update(@PathVariable Long id, @Valid @RequestBody KnowledgeRequest req) {
        return Result.success(knowledgeService.update(id, SecurityUtil.getCurrentUserId(), req));
    }

    @Operation(summary = "删除知识条目")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        knowledgeService.delete(id, SecurityUtil.getCurrentUserId());
        return Result.success();
    }

    @Operation(summary = "导入文件（TXT/MD）")
    @PostMapping("/import")
    public Result<KnowledgeVO> importFile(@RequestParam MultipartFile file) throws IOException {
        return Result.success(knowledgeService.importFile(SecurityUtil.getCurrentUserId(), file));
    }
}
