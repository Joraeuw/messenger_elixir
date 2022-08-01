import React, { useState, useEffect, useContext } from "react";

import { Context } from "../context";

// import dynamic from "next/dynamic";
import { useRouter } from "next/router";
import axios from "axios";

export default function Home() {
  const { email, password } = useContext(Context);
  const [showChat, setShowChat] = useState(false);
  const [data, setData] = useState(null);
  const router = useRouter();

  console.log(email, password);
  setInterval(() => {
    async function fetchData() {
      user = await axios.get(
        "http://localhost:8080/",
        {},
        {
          auth: {
            username: email,
            password: password,
          },
        }
      );
      friends = await axios.get(
        "http://localhost:8080/friends",
        {},
        {
          auth: {
            username: email,
            password: password,
          },
        }
      );
      setData({ user: user, friends: friends });
    }
    fetchData();
  }, 500);
  console.log(data);

  useEffect(() => {
    if (typeof document !== undefined) {
      setShowChat(true);
    }
  }, []);

  useEffect(() => {
    if (email === "" || password === "") {
      router.push("/");
    }
  }, [email, password]);

  if (!showChat) return <div />;

  return (
    <div className="background">
      <div className="shadow">
        <div className="chat-container">
          <ul className="chat=list"></ul>
        </div>
      </div>
    </div>
  );
}
