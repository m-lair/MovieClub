import { Timestamp } from 'firebase-admin/firestore';

export interface MovieData {
  likes: number;
  dislikes: number;
  numCollected: number;
  status: "active" | "archived";
  startDate: Date | Timestamp;
  endDate: Date | Timestamp;
  numComments: number;
  imdbId: string;
  collectedBy: string[];
  likedBy: string[];
  dislikedBy: string[];
  userId: string;
  userName: string;
  movieClubId: string;
}

export interface CreateMovieData extends MovieData {
  id: string;
}

export interface MovieLikeRequest {
  movieId: string;
  clubId: string;
}

export interface MovieReactionData {
  likes: number;
  likedBy: string[];
  dislikes: number;
  dislikedBy: string[];
  
}
