export interface PosterData {
    imdbId: string;
    posterUrl: string;
    colorStr: string;
    clubId: string;
    clubName: string;
}

export interface CollectPosterData extends PosterData {
    id: string;
}