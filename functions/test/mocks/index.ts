import { logVerbose } from "helpers";
import { populateCommentData } from "./comment";
import { populateMovieClubData } from "./movieclub";
import { populateMovieData } from "./movie";
import { populateMembershipData } from "./membership";
import { populateMemberData } from "./member";
import { populateUserData } from "./user";

async function populateDefaultData(count = 1, params: any) {
  logVerbose("Populating default data...");
  const data = [];

  for (let i = 0; i < count; i++) {
    logVerbose(`Populating data for user ${i}`);
    const { user, auth } = await populateUserData({
      id: `${i}`,
      ...(params.user || {}),
    });
    const movieClub = await populateMovieClubData({
      id: `${i}`,
      ownerId: user?.id,
      ownerName: user?.name,
      ...(params.movieclub || {}),
    });
    const movie = await populateMovieData({
      id: `${i}`,
      movieClubId: movieClub?.id,
      ...(params.movie || {}),
    });
    const membership = await populateMembershipData({
      userId: user?.id,
      clubId: movieClub?.id,
      clubName: movieClub?.name,
      ...(params.membership || {}),
    });
    const member = await populateMemberData({
      id: user?.id,
      name: user?.name,
      movieClubId: movieClub?.id,
      ...(params.member || {}),
    });
    const comment = await populateCommentData({
      id: `${i}`,
      name: user?.name,
      movieClubId: movieClub?.id,
      movieId: movie.id,
      ...(params.comment || {}),
    });

    data.push({ user, auth, movieClub, movie, membership, member, comment });
  }

  return data;
}

export {
  populateCommentData,
  populateDefaultData,
  populateMemberData,
  populateMovieData,
  populateMovieClubData,
  populateUserData,
};
