export interface UserData {
  bio?: string;
  image?: string;
  name: string;
  createdAt?: number;
}

export interface CreateUserWithEmailData extends UserData {
  email: string;
  password: string;
};

export interface CreateUserWithOAuthData extends UserData {
  email: string;
  signInProvider: string;
};

export interface UpdateUserData extends UserData {
  id: string;
}