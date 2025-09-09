// Learn more about configuration options: https://github.com/johnste/finicky/wiki/Configuration

export default {
  defaultBrowser: "Firefox",
  handlers: [
    {
      // Open Zoom SSO links in a typical browser
      match: ({opener, url }) => opener.bundleId == "us.zoom.xos" && url.host.includes("zoom.us"),
      browser: "Firefox",
    },
    {
      // make zoom links open in zoom 
      match: [
        "zoom.us/*",
        (url) => finicky.matchHostnames(/.*\zoom.us/) && !url.pathname.startsWith("/rec/share/"),
        /zoom.us\/j\//,
      ],
     browser: "/Applications/zoom.us.app",
    },
    {
      // MS Teams
      match: finicky.matchHostnames(['teams.microsoft.com']),
      browser: '/Applications/Microsoft\ Teams.app',
      url: ({url}) => ({...url, protocol: 'msteams'}),
    },
    {
      // Slack protocol
      match: ({ url }) => url.protocol === "slack",
      browser: "/Applications/Slack.app"
    },
  ],

  rewrite: [
    {
      // Rewrite Slack https urls to Slack protocol urls
      match: [
        'app.slack.com/huddle/*',
      ],
      url: ({url}) => {
        // ignores /huddle/
        const [team, id] = url.pathname.split("/").slice(2)

        return {
          protocol: 'slack',
          host: '',
          pathname: 'join-huddle',
          search: `team=${team}&id=${id}`,
        }
      }
    }
  ]
}
