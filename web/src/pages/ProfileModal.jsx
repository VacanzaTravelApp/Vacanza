import React from "react";
import { Modal, Avatar, Typography, Button } from "antd";
import { TrophyOutlined, RightOutlined, UserOutlined } from "@ant-design/icons";
import { useNavigate } from "react-router-dom";

const { Text, Title } = Typography;

const ProfileModal = ({ open, onClose, user, gamification, gamificationLoading }) => {
    const navigate = useNavigate();

    return (
        <Modal
            open={open}
            onCancel={onClose}
            footer={null}
            width={400}
            centered
            closeIcon={false}
            bodyStyle={{ padding: "30px 24px" }}
            style={{ borderRadius: 24, overflow: "hidden" }}
        >
            <Title level={3} style={{ marginTop: 0, marginBottom: 24, fontWeight: 800, color: "#111827" }}>
                Profile
            </Title>

            {/* Profile Card */}
            <div
                style={{
                    background: "linear-gradient(135deg, #e0f7fa 0%, #e8f5e9 100%)",
                    borderRadius: 20,
                    padding: 24,
                    display: "flex",
                    alignItems: "center",
                    gap: 20,
                    marginBottom: 16,
                }}
            >
                <div style={{ position: "relative" }}>
                    <div
                        style={{
                            width: 72,
                            height: 72,
                            borderRadius: "50%",
                            padding: 3,
                            background: "linear-gradient(45deg, #00acc1, #4caf50)",
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                        }}
                    >
                        <Avatar
                            size={66}
                            src={user?.photoURL}
                            icon={!user?.photoURL && <UserOutlined />}
                            style={{ border: "2px solid white", background: "#1890ff" }}
                        />
                    </div>
                    {/* Level Badge placed on avatar */}
                    <div
                        style={{
                            position: "absolute",
                            bottom: 0,
                            right: 0,
                            background: "#ffb74d",
                            color: "#fff",
                            fontWeight: 800,
                            fontSize: 12,
                            borderRadius: 12,
                            padding: "2px 6px",
                            border: "2px solid #fff",
                            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
                        }}
                    >
                        {gamification?.level || 1}
                    </div>
                </div>

                <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 20, fontWeight: 800, color: "#111827", lineHeight: 1.2 }}>
                        {user?.displayName || "Traveler"}
                    </div>
                    <div
                        style={{
                            display: "inline-block",
                            background: "rgba(255, 255, 255, 0.7)",
                            borderRadius: 12,
                            padding: "2px 10px",
                            fontSize: 12,
                            fontWeight: 600,
                            color: "#455a64",
                            marginTop: 6,
                            marginBottom: 8,
                        }}
                    >
                        {gamification?.roleText || "Newbie"}
                    </div>
                    <div style={{ fontSize: 13, fontWeight: 600, color: "#00838f" }}>
                        {gamificationLoading
                            ? "Loading..."
                            : `Level ${gamification?.level || 1} • ${gamification?.totalXp || 0} XP`}
                    </div>
                </div>
            </div>

            {/* Gamification Navigation Card */}
            <div
                onClick={() => {
                    onClose();
                    navigate("/gamification");
                }}
                style={{
                    background: "#fff",
                    border: "1px solid #f0f0f0",
                    borderRadius: 20,
                    padding: "20px 24px",
                    display: "flex",
                    alignItems: "center",
                    gap: 16,
                    cursor: "pointer",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.03)",
                    transition: "transform 0.2s, box-shadow 0.2s",
                }}
                onMouseOver={(e) => {
                    e.currentTarget.style.transform = "translateY(-2px)";
                    e.currentTarget.style.boxShadow = "0 8px 16px rgba(0,0,0,0.08)";
                }}
                onMouseOut={(e) => {
                    e.currentTarget.style.transform = "translateY(0)";
                    e.currentTarget.style.boxShadow = "0 4px 12px rgba(0,0,0,0.03)";
                }}
            >
                <div
                    style={{
                        width: 48,
                        height: 48,
                        borderRadius: 14,
                        background: "linear-gradient(135deg, #ffb74d 0%, #ff9800 100%)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        flexShrink: 0,
                    }}
                >
                    <TrophyOutlined style={{ fontSize: 24, color: "#fff" }} />
                </div>
                <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 16, fontWeight: 700, color: "#111827", marginBottom: 2 }}>
                        Gamification
                    </div>
                    <div style={{ fontSize: 13, color: "#6b7280" }}>XP, badges, and challenges</div>
                </div>
                <RightOutlined style={{ color: "#9ca3af" }} />
            </div>
        </Modal>
    );
};

export default ProfileModal;
