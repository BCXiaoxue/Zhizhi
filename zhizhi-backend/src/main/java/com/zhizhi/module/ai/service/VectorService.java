package com.zhizhi.module.ai.service;

import com.zhizhi.module.knowledge.entity.Knowledge;
import com.zhizhi.module.knowledge.service.KnowledgeService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Slf4j
@Service
public class VectorService {

    private final VectorStore vectorStore;
    private final KnowledgeService knowledgeService;

    public VectorService(@Lazy VectorStore vectorStore, KnowledgeService knowledgeService) {
        this.vectorStore = vectorStore;
        this.knowledgeService = knowledgeService;
    }

    public void vectorize(Knowledge knowledge) {
        String text = knowledge.getTitle() + "\n" + knowledge.getContent();
        Document doc = Document.builder()
                .id(knowledge.getId().toString())
                .text(text)
                .metadata(Map.of(
                        "knowledgeId", knowledge.getId().toString(),
                        "title", knowledge.getTitle()
                ))
                .build();
        vectorStore.add(List.of(doc));
        knowledgeService.markVectorized(knowledge.getId());
        log.info("知识条目 {} 向量化成功", knowledge.getId());
    }

    public List<Document> search(String query, int topK) {
        return vectorStore.similaritySearch(
                SearchRequest.builder().query(query).topK(topK).similarityThreshold(0.6).build()
        );
    }

    public void delete(Long knowledgeId) {
        try {
            vectorStore.delete(List.of(knowledgeId.toString()));
        } catch (Exception e) {
            log.warn("删除向量失败，knowledgeId={}", knowledgeId, e);
        }
    }

    public void vectorizeAll(Long userId) {
        List<Knowledge> list = knowledgeService.getUnvectorized(userId);
        for (Knowledge k : list) {
            try {
                vectorize(k);
            } catch (Exception e) {
                log.error("批量向量化失败，knowledgeId={}", k.getId(), e);
            }
        }
    }
}
