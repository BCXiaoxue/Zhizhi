package com.zhizhi.module.knowledge.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.zhizhi.common.BusinessException;
import com.zhizhi.common.PageResult;
import com.zhizhi.module.knowledge.dto.KnowledgeRequest;
import com.zhizhi.module.knowledge.dto.KnowledgeVO;
import com.zhizhi.module.knowledge.entity.Knowledge;
import com.zhizhi.module.knowledge.mapper.KnowledgeMapper;
import com.zhizhi.module.tag.service.TagService;
import lombok.RequiredArgsConstructor;
import org.apache.commons.io.FilenameUtils;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Service
@RequiredArgsConstructor
public class KnowledgeService extends ServiceImpl<KnowledgeMapper, Knowledge> {

    private final TagService tagService;
    private final JdbcTemplate jdbcTemplate;

    @Transactional
    public KnowledgeVO create(Long userId, KnowledgeRequest req) {
        Knowledge knowledge = new Knowledge();
        knowledge.setUserId(userId);
        knowledge.setTitle(req.getTitle());
        knowledge.setContent(req.getContent());
        knowledge.setCategoryId(req.getCategoryId());
        knowledge.setIsVectorized(0);
        save(knowledge);
        saveTags(knowledge.getId(), userId, req.getTags());
        return getDetailVO(knowledge.getId(), userId);
    }

    @Transactional
    public KnowledgeVO update(Long id, Long userId, KnowledgeRequest req) {
        Knowledge knowledge = getOwned(id, userId);
        knowledge.setTitle(req.getTitle());
        knowledge.setContent(req.getContent());
        knowledge.setCategoryId(req.getCategoryId());
        knowledge.setIsVectorized(0); // 内容变更，需重新向量化
        updateById(knowledge);
        jdbcTemplate.update("DELETE FROM knowledge_tag WHERE knowledge_id = ?", id);
        saveTags(id, userId, req.getTags());
        return getDetailVO(id, userId);
    }

    @Transactional
    public void delete(Long id, Long userId) {
        getOwned(id, userId);
        removeById(id);
        jdbcTemplate.update("DELETE FROM knowledge_tag WHERE knowledge_id = ?", id);
    }

    public PageResult<KnowledgeVO> page(Long userId, Long categoryId, Long tagId, long current, long size) {
        Page<KnowledgeVO> page = new Page<>(current, size);
        baseMapper.selectPageVO(page, userId, categoryId, tagId);
        return PageResult.of(page);
    }

    public KnowledgeVO getDetailVO(Long id, Long userId) {
        KnowledgeVO vo = baseMapper.selectDetailVO(id);
        if (vo == null) throw BusinessException.notFound("知识条目");
        vo.parseTagsFromStr();
        return vo;
    }

    public List<KnowledgeVO> search(Long userId, String keyword) {
        return baseMapper.searchByFullText(userId, keyword);
    }

    @Transactional
    public KnowledgeVO importFile(Long userId, MultipartFile file) throws IOException {
        String ext = FilenameUtils.getExtension(file.getOriginalFilename());
        if (!"txt".equalsIgnoreCase(ext) && !"md".equalsIgnoreCase(ext)) {
            throw new BusinessException(400, "仅支持 .txt 和 .md 文件");
        }
        String content = new String(file.getBytes(), StandardCharsets.UTF_8);
        String title = FilenameUtils.getBaseName(file.getOriginalFilename());
        KnowledgeRequest req = new KnowledgeRequest();
        req.setTitle(title);
        req.setContent(content);
        return create(userId, req);
    }

    public void updateSummary(Long id, Long userId, String summary) {
        getOwned(id, userId);
        update(new LambdaUpdateWrapper<Knowledge>()
                .eq(Knowledge::getId, id)
                .set(Knowledge::getSummary, summary));
    }

    public void markVectorized(Long id) {
        update(new LambdaUpdateWrapper<Knowledge>()
                .eq(Knowledge::getId, id)
                .set(Knowledge::getIsVectorized, 1));
    }

    public List<Knowledge> getUnvectorized(Long userId) {
        return list(new LambdaQueryWrapper<Knowledge>()
                .eq(Knowledge::getUserId, userId)
                .eq(Knowledge::getIsVectorized, 0));
    }

    private Knowledge getOwned(Long id, Long userId) {
        Knowledge knowledge = getById(id);
        if (knowledge == null) throw BusinessException.notFound("知识条目");
        if (!knowledge.getUserId().equals(userId)) throw BusinessException.forbidden();
        return knowledge;
    }

    private void saveTags(Long knowledgeId, Long userId, List<String> tagNames) {
        if (tagNames == null || tagNames.isEmpty()) return;
        List<Long> tagIds = tagService.getOrCreateTagIds(userId, tagNames);
        if (tagIds.isEmpty()) return;
        jdbcTemplate.batchUpdate(
            "INSERT IGNORE INTO knowledge_tag (knowledge_id, tag_id) VALUES (?, ?)",
            tagIds.stream().map(tagId -> new Object[]{knowledgeId, tagId}).toList()
        );
    }
}
