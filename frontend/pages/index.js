import React, { useContext } from "react";

import { Context } from "../context";

import { useRouter } from "next/router";

import axios from "axios";

const Auth = () => {
  const { email, setEmail, password, setPassword } = useContext(Context);

  const router = useRouter();

  function onSubmit(e) {
    e.preventDefault();

    if (email.length < 6 || password.length < 6) return;
    axios
      .post(
        "http://localhost:8080/login",
        {},
        {
          auth: {
            username: email,
            password: password,
          },
        }
      )
      .then((res) => {
        if (res.data == "Authorized") {
          router.push("/chats");
        }
        if (res.data == "Unauthorized") return;
      })
      .catch((err) => console.log("ERROR: " + err));
  }

  return (
    <div className="background">
      <div className="auth-container">
        <form className="auth-form" onSubmit={(e) => onSubmit(e)}>
          <div className="auth-title">NextJS Chat</div>

          <div className="input-container">
            <input
              placeholder="Email"
              className="text-input"
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>

          <div className="input-container">
            <input
              type="password"
              placeholder="Password"
              className="text-input"
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          <button type="submit" className="submit-button">
            Login / Sign Up
          </button>
        </form>
      </div>
    </div>
  );
};

export default Auth;
