package com.zhizhi.module.knowledge.dto;

import com.fasterxml.jackson.annotation.JsonIgnore;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Data
public class KnowledgeVO {
    private Long id;
    private String title;
    private String content;
    private String summary;
    private Long categoryId;
    private String categoryName;
    private Integer viewCount;
    private Integer isVectorized;
    private List<String> tags;
    /** MyBatis 用 GROUP_CONCAT 结果填入此字段，由 Service 层转换为 tags */
    @JsonIgnore
    private String tagsStr;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public void parseTagsFromStr() {
        if (tagsStr != null && !tagsStr.isBlank()) {
            this.tags = Arrays.asList(tagsStr.split(","));
        }
    }
}
