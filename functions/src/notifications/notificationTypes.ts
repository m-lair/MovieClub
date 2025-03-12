export interface NotificationData {
    clubName: string;
    clubId: string;
    userName: string;
    userId: string;
    othersCount?: number | null;
    imdbId?: string;
    message: string;
    createdAt: Date;
    type: string;
}

// Define notification types to match Swift enum
export enum NotificationType {
    LIKED = "liked",
    COMMENTED = "commented",
    REPLIED = "replied",
    COLLECTED = "collected",
    SUGGESTION = "suggestion",
    JOINED = "joined"
}