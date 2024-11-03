export interface MovieData {
    title: string;
    likes: number;
    dislikes: number;
    collected: boolean;
    numCollected: number;
    numComments: number;
    imdbId: string;
}

export interface CreateMovieData extends MovieData {
    id: string;
}