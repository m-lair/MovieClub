import { firebaseAdmin } from "firestore";

export interface CommentData {
  text: string;
  userId: string;
  username: string;
  image?: string;
  likes?: number;
  createdAt?: string | firebaseAdmin.firestore.FieldValue;
}

interface CommentDataAssociations {
  movieClubId: string;
  movieId: string;
}

export interface PostCommentData extends CommentData, CommentDataAssociations {}

export interface DeleteCommentData extends CommentDataAssociations {
  id: string;
}