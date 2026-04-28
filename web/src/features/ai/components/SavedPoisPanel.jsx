import React from "react";
import { Button, Spin } from "antd";
import { CloseOutlined, EnvironmentOutlined, DeleteOutlined, HeartOutlined } from "@ant-design/icons";
import { useQueryClient } from "@tanstack/react-query";
import { useSavedPois } from "../../../hooks/useSavedPois";
import { postPoiFeedbackEvent } from "../../../api/feedbackApi";
import { getCategoryColor } from "../../../constants/categoryColors";
import { toast } from "../../../components/toast/toast";
import { getErrorNotificationMessage } from "../../../utils/notifications";
import "../styles/savedPoisPanel.css";

function formatCategory(cat) {
  if (!cat) return null;
  return cat.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
}

function formatDate(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? ""
    : d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

export default function SavedPoisPanel({ onClose, onFlyTo }) {
  const { data: pois, isLoading } = useSavedPois();
  const queryClient = useQueryClient();

  const handleRemove = async (poi) => {
    try {
      await postPoiFeedbackEvent({
        eventType: "THUMBS_DOWN",
        waypointName: poi.name,
        latitude: poi.latitude,
        longitude: poi.longitude,
        categoryKeys: poi.category ? [poi.category] : null,
      });
      queryClient.invalidateQueries({ queryKey: ["feedback", "saved-pois"] });
      queryClient.invalidateQueries({ queryKey: ["feedback", "affinity"] });
    } catch (error) {
      toast.error({
        title: "Couldn't remove",
        message: getErrorNotificationMessage(error, "Failed to remove this place. Please try again."),
      });
    }
  };

  const count = pois?.length ?? 0;

  return (
    <div className="saved-pois-panel">
      {/* Header */}
      <div className="saved-pois-header">
        <div className="saved-pois-title">
          <HeartOutlined className="saved-pois-icon" />
          <span className="saved-pois-title-text">Saved Places</span>
          {count > 0 && (
            <span className="saved-pois-count">{count}</span>
          )}
        </div>
        <Button
          type="text"
          size="small"
          icon={<CloseOutlined />}
          onClick={onClose}
          className="saved-pois-close"
          aria-label="Close saved places"
        />
      </div>

      {/* Body */}
      <div className="saved-pois-body">
        {isLoading && (
          <div className="saved-pois-loading">
            <Spin size="small" />
          </div>
        )}

        {!isLoading && count === 0 && (
          <div className="saved-pois-empty-wrap">
            <HeartOutlined className="saved-pois-empty-icon" />
            <span className="saved-pois-empty-text">No saved places yet</span>
            <span className="saved-pois-empty-sub">
              Like a place from the map or your route to save it here.
            </span>
          </div>
        )}

        {!isLoading && count > 0 && (
          <ul className="saved-pois-list">
            {pois.map((poi) => {
              const color = getCategoryColor(poi.category);
              const hasCoords = poi.latitude != null && poi.longitude != null;
              return (
                <li key={poi.poiKey} className="saved-poi-item">
                  <button
                    type="button"
                    className="saved-poi-main"
                    onClick={() => {
                      if (hasCoords && onFlyTo) {
                        onFlyTo(poi.latitude, poi.longitude);
                      }
                    }}
                    disabled={!hasCoords}
                    title={hasCoords ? "Show on map" : undefined}
                  >
                    <div
                      className="saved-poi-dot"
                      style={{ background: color || "var(--vc-primary)" }}
                    />
                    <div className="saved-poi-info">
                      <span className="saved-poi-name">{poi.name}</span>
                      <div className="saved-poi-meta">
                        {poi.category && (
                          <span className="saved-poi-category">
                            {formatCategory(poi.category)}
                          </span>
                        )}
                        <span className="saved-poi-date">{formatDate(poi.updatedAt)}</span>
                      </div>
                    </div>
                    {hasCoords && (
                      <EnvironmentOutlined className="saved-poi-map-icon" />
                    )}
                  </button>
                  <button
                    type="button"
                    className="saved-poi-remove"
                    onClick={(e) => {
                      e.stopPropagation();
                      handleRemove(poi);
                    }}
                    aria-label="Remove from saved"
                    title="Remove"
                  >
                    <DeleteOutlined />
                  </button>
                </li>
              );
            })}
          </ul>
        )}
      </div>

      {/* Footer */}
      {!isLoading && count > 0 && (
        <div className="saved-pois-footer">
          <span className="saved-pois-footer-text">
            {count} place{count !== 1 ? "s" : ""} saved
          </span>
        </div>
      )}
    </div>
  );
}
