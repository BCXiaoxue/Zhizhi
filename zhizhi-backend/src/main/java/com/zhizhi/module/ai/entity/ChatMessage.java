package com.zhizhi.module.ai.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("chat_message")
public class ChatMessage {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long sessionId;
    private String role;      // user / assistant
    private String content;
    private String sources;   // JSON 字符串，引用的知识条目 ID 列表
    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;
}
