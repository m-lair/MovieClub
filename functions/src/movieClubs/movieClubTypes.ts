export interface MovieClubData {
  description: string;
  isPublic: boolean;
  name: string;
  numMembers: number;
  ownerId: string;
  ownerName: string;
  timeInterval: number;
  createdAt?: number;
}

export interface UpdateMovieClubData extends MovieClubData {
  id: string;
}
