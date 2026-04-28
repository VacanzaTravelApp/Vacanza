package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.service.PoiSearchService;
import com.vacanza.backend.validation.PoiAreaRequestValidator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.concurrent.Executor;

@Slf4j
@RestController
@RequestMapping("/pois")
public class PoiController {

    private final PoiSearchService poiSearchService;
    private final PoiAreaRequestValidator poiAreaRequestValidator;
    private final Executor poiStreamExecutor;

    public PoiController(
            PoiSearchService poiSearchService,
            PoiAreaRequestValidator poiAreaRequestValidator,
            @Qualifier("poiStreamExecutor") Executor poiStreamExecutor) {
        this.poiSearchService = poiSearchService;
        this.poiAreaRequestValidator = poiAreaRequestValidator;
        this.poiStreamExecutor = poiStreamExecutor;
    }

    private static boolean isClientDisconnected(Throwable e) {
        for (Throwable t = e; t != null; t = t.getCause()) {
            String cn = t.getClass().getName();
            if (cn.contains("AsyncRequestNotUsableException") || cn.contains("EofException")) return true;
            String msg = t.getMessage();
            if (msg != null && (msg.contains("Broken pipe") || msg.contains("Connection reset"))) return true;
        }
        return false;
    }

    @PostMapping("/search-in-area")
    public ResponseEntity<PoiSearchInAreaResponseDTO> searchInArea(@RequestBody PoiSearchInAreaRequestDTO req) {
        return new ResponseEntity<>(poiSearchService.searchInArea(req), HttpStatus.OK);
    }

    /**
     * Progressive Mapbox POI search: SSE events with JSON bodies — {@code chunk} then {@code done}.
     * Requires {@code mapboxAreaSearch: true} (same body as {@link #searchInArea}).
     */
    @PostMapping(value = "/search-in-area/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter searchInAreaStream(@RequestBody PoiSearchInAreaRequestDTO req) {
        poiAreaRequestValidator.validate(req);
        if (!Boolean.TRUE.equals(req.getMapboxAreaSearch())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "MAPBOX_STREAM_REQUIRED: mapboxAreaSearch must be true for streaming endpoint");
        }

        SseEmitter emitter = new SseEmitter(480_000L);
        emitter.onTimeout(() -> log.warn("[POI SSE] timeout"));
        poiStreamExecutor.execute(() -> {
            try {
                poiSearchService.forEachMapboxStreamChunk(req, payload -> {
                    try {
                        emitter.send(SseEmitter.event().data(payload));
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                });
                emitter.complete();
            } catch (Exception e) {
                if (isClientDisconnected(e)) {
                    log.debug("[POI SSE] client disconnected mid-stream");
                    emitter.complete();
                } else {
                    log.warn("[POI SSE] failed: {}", e.toString());
                    emitter.completeWithError(e);
                }
            }
        });
        return emitter;
    }
}
