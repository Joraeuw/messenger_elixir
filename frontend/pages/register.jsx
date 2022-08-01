import { useState } from "react";
import styles from "../styles/Register.module.css";
import { useRouter } from "next/router";
import axios from "axios";

export default function Register() {
  const [email, setEmail] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const emailRegex = /^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$/;
  const router = useRouter();
  function onSubmit(e) {
    e.preventDefault();
    if (!emailRegex.test(email) || username < 6 || password < 6) return;

    axios
      .post(
        "http://localhost:8080/register",
        {
          email,
          username,
          password,
          bio: "",
        },
        {}
      )
      .then((res) => {
        if (res.data == "successful registration") router.push("/");
      });
  }
  return (
    <div className="background" style={{ paddingTop: "80px" }}>
      <div
        className="auth-container"
        style={{ marginTop: "0px", height: "85vh" }}
      >
        <form className="auth-form" onSubmit={(e) => onSubmit(e)}>
          <div className="auth-title">SignUp</div>

          <div className="input-container">
            <input
              placeholder="Email"
              className="text-input"
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="input-container">
            <input
              placeholder="Username"
              className="text-input"
              onChange={(e) => setUsername(e.target.value)}
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
            Sign Up
          </button>
        </form>
      </div>
    </div>
  );
}
