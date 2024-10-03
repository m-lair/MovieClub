import { firebaseAdmin } from "firestore";

export interface MovieClubData {
  bannerUrl: string;
  description: string;
  image: string;
  isPublic: boolean;
  name: string;
  ownerId: string;
  ownerName: string;
  timeInterval: string;
  createdAt?: number;
}

export interface UpdateMovieClubData extends MovieClubData {
  id: string
};