export interface CommentData {
  text: string;
  userId: string;
  userName: string;
  image?: string;
  likes: number;
  createdAt: Date;
}

interface CommentDataAssociations {
  clubId: string;
  movieId: string;
}

export interface PostCommentData extends CommentData, CommentDataAssociations {}

export interface DeleteCommentData extends CommentDataAssociations {
  id: string;
}
