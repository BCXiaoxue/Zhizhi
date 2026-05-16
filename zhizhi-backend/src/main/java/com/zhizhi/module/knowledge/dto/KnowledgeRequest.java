package com.zhizhi.module.knowledge.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;

@Data
public class KnowledgeRequest {
    @NotBlank(message = "标题不能为空")
    private String title;
    private String content;
    private Long categoryId;
    private List<String> tags;
}
