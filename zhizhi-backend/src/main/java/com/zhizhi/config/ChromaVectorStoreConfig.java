package com.zhizhi.config;

import io.micrometer.observation.ObservationRegistry;
import org.springframework.ai.chroma.vectorstore.ChromaApi;
import org.springframework.ai.chroma.vectorstore.ChromaVectorStore;
import org.springframework.ai.embedding.BatchingStrategy;
import org.springframework.ai.embedding.EmbeddingModel;
import org.springframework.ai.vectorstore.chroma.autoconfigure.ChromaVectorStoreProperties;
import org.springframework.ai.vectorstore.observation.VectorStoreObservationConvention;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ChromaVectorStoreConfig {

    @Bean
    public ChromaVectorStore vectorStore(
            EmbeddingModel embeddingModel,
            ChromaApi chromaApi,
            ChromaVectorStoreProperties properties,
            ObjectProvider<ObservationRegistry> observationRegistry,
            ObjectProvider<VectorStoreObservationConvention> observationConvention,
            ObjectProvider<BatchingStrategy> batchingStrategy) {

        ensureCollectionExists(chromaApi, properties);

        ChromaVectorStore.Builder builder = ChromaVectorStore.builder(chromaApi, embeddingModel)
                .tenantName(properties.getTenantName())
                .databaseName(properties.getDatabaseName())
                .collectionName(properties.getCollectionName())
                .initializeSchema(properties.isInitializeSchema());

        ObservationRegistry registry = observationRegistry.getIfAvailable();
        if (registry != null) {
            builder.observationRegistry(registry);
        }

        VectorStoreObservationConvention convention = observationConvention.getIfAvailable();
        if (convention != null) {
            builder.customObservationConvention(convention);
        }

        BatchingStrategy strategy = batchingStrategy.getIfAvailable();
        if (strategy != null) {
            builder.batchingStrategy(strategy);
        }

        return builder.build();
    }

    private void ensureCollectionExists(ChromaApi chromaApi, ChromaVectorStoreProperties properties) {
        String tenantName = properties.getTenantName();
        String databaseName = properties.getDatabaseName();
        String collectionName = properties.getCollectionName();

        if (chromaApi.getTenant(tenantName) == null) {
            chromaApi.createTenant(tenantName);
        }

        if (chromaApi.getDatabase(tenantName, databaseName) == null) {
            chromaApi.createDatabase(tenantName, databaseName);
        }

        boolean collectionExists = chromaApi.listCollections(tenantName, databaseName).stream()
                .anyMatch(collection -> collectionName.equals(collection.name()));

        if (!collectionExists) {
            chromaApi.createCollection(
                    tenantName,
                    databaseName,
                    new ChromaApi.CreateCollectionRequest(collectionName));
        }
    }
}
