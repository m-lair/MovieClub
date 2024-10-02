export interface UserData {
  name: string;
  email: string;
  id?: string;
  bio?: string;
  image?: string;
}

export interface CreateUserWithEmailData extends UserData {
  password: string;
};

export interface CreateUserWithOAuthData extends UserData {
  signInProvider: string;
};

export interface UpdateUserData {
  id: string;
  name?: string;
  bio?: string;
  image?: string;
}