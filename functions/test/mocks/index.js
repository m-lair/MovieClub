const { logVerbose } = require("utilities")
const { populateCommentData } = require("./comment")
const { populateMovieClubData } = require("./movieclub")
const { populateMovieData } = require("./movie")
const { populateMembershipData } = require("./membership")
const { populateMemberData } = require("./member")
const { populateUserData } = require("./user")

async function populateDefaultData(count = 1, params = {}) {
  logVerbose('Populating default data...');
  let data = []

  for (let i = 0; i < count; i++) {
    logVerbose(`Populating data for user ${i}`);
    const user = await populateUserData({ id: `${i}`, ...params.user || {} });
    const movieClub = await populateMovieClubData({ id: `${i}`, ownerID: user.uid, ownerName: user.name, ...params.movieclub || {} });
    const movie = await populateMovieData({ id: `${i}`, movieClubId: movieClub.id, ...params.movie || {} });
    const membership = await populateMembershipData({ userId: user.uid, clubID: movieClub.id, clubName: movieClub.name, ...params.membership || {} });
    const member = await populateMemberData({ id: user.uid, name: user.name, movieClubId: movieClub.id, ...params.member || {} });
    const comment = await populateCommentData({ id: `${i}`, name: user.name, movieClubId: movieClub.id, movieId: movie.id, ...params.comment || {} });

    data.push({ user, movieClub, movie, membership, member, comment })
  }

  return data;
}

module.exports = {
  populateCommentData,
  populateDefaultData,
  populateMemberData,
  populateMovieData,
  populateMovieClubData,
  populateUserData,
}