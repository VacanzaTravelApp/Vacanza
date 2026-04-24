package com.vacanza.backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import java.util.concurrent.Executor;

@Configuration
public class PoiStreamExecutorConfig {

    @Bean(name = "poiStreamExecutor")
    public Executor poiStreamExecutor() {
        ThreadPoolTaskExecutor ex = new ThreadPoolTaskExecutor();
        ex.setCorePoolSize(2);
        ex.setMaxPoolSize(6);
        ex.setQueueCapacity(80);
        ex.setThreadNamePrefix("poi-mapbox-stream-");
        ex.initialize();
        return ex;
    }
}
