import { List, ListItem, CopyToClipboardAction, ActionPanel } from "@raycast/api";
import * as fs from "fs";
import os from "os";
import { useEffect, useState } from "react";

const CONFIG = `${os.homedir}/.aws/config`;

export default function Command() {
  const [profiles, setProfiles] = useState<string[]>([]);

  useEffect(() => {
    const buffer = fs.readFileSync(CONFIG);
    const s = buffer.toString();
    let result = [],
      m,
      rx = /\[profile (.*?)\]/g;

    while ((m = rx.exec(s)) !== null) {
      result.push(m[1]);
    }

    setProfiles(result.sort());
  }, []);

  const renderProfile = (item: string, index: number) => {
    return (
      <ListItem
        key={index}
        title={item}
        actions={
          <ActionPanel>
            <CopyToClipboardAction content={item} />
          </ActionPanel>
        }
      />
    );
  };

  return <List>{profiles.map(renderProfile)}</List>;
}
