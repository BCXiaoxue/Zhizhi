package com.zhizhi.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class Knife4jConfig {

    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("智知 ZhiZhi API")
                        .description("AI驱动的个人知识管理与智能问答系统接口文档")
                        .version("1.0.0"));
    }
}
