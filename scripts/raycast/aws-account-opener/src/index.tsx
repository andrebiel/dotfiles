import { List, ListItem, CopyToClipboardAction, ActionPanel } from "@raycast/api";
import * as fs from "fs";
import os from "os";
import { useEffect, useState } from "react";

const CONFIG = `${os.homedir}/.aws/config`;

interface AwsCredential {
  sso_start_url?: string;
  sso_region?: string;
  sso_account_id?: string;
  sso_role_name?: string;
  region?: string;
  output?: string;
}
type StateType = Record<string, AwsCredential>;

export default function Command() {
  const [profiles, setProfiles] = useState<StateType>({});

  useEffect(() => {
    const buffer = fs.readFileSync(CONFIG);
    const fileContent = buffer.toString().split(/\r?\n/);
    let currentParent = "";
    const result: StateType = {};
    fileContent.forEach((line) => {
      const trimmedLine = line.trim();

      if (trimmedLine.startsWith("[") && trimmedLine.endsWith("]")) {
        const profileRegex = new RegExp(/\[profile(.*)\]/gm);
        const match = profileRegex.exec(trimmedLine);
        const profileName = match?.[1]?.trim() || trimmedLine;
        currentParent = profileName;
        result[profileName] = {};
        return;
      }

      const splitted = line.split("=");
      const identifier = splitted[0]?.trim() as keyof AwsCredential;
      const value = splitted[1]?.trim();

      if (value && identifier) {
        result[currentParent][identifier] = value;
      }
    });

    setProfiles(result);
  }, []);

  const renderProfile = (profile: keyof StateType, index: number) => {
    const cred = profiles[profile];

    return (
      <ListItem
        key={index}
        title={profile}
        subtitle={cred?.sso_account_id}
        actions={
          <ActionPanel>
            <CopyToClipboardAction content={`export AWS_PROFILE=${profile}`} />
          </ActionPanel>
        }
      />
    );
  };

  return <List>{Object.keys(profiles).map(renderProfile)}</List>;
}
