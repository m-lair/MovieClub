export interface CommentData {
  text: string;
  userId: string;
  userName: string;
  image?: string;
  likes: number;
  likedBy: string[];
  parentId?: string;
  createdAt: Date;
}

interface ReplyData extends CommentData {
  replyToId: string;
}

interface CommentDataAssociations {
  clubId: string;
  movieId: string;
}

export interface LikeCommentData {
  clubId: string;
  movieId: string;
  commentId: string;
}

export interface UnlikeCommentData {
  clubId: string;
  movieId: string;
  commentId: string;
}

export interface AnonymizeCommentData {
  clubId: string;
  movieId: string;
  commentId: string;
}

export interface ReportCommentData {
  clubId: string;
  movieId: string;
  commentId: string;
  reason: string;
}

export interface PostCommentData extends CommentData, ReplyData, CommentDataAssociations { }

/**
 * @deprecated Use AnonymizeCommentData instead
 */
export interface DeleteCommentData extends CommentDataAssociations {
  id: string;
}
