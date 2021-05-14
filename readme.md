This started off by following along guides from two fantastic content creators. It was primarily meant as a learning experience for me, but I'm sharing my modifications in case someone finds something useful/helpful for their own situation. If that is you, consider showing some love to these content creators:

https://www.traversymedia.com/

https://devopsdirective.com/

Since following the initial devopsdirective guide, I completely reworked deployment. Because this is a hobby project and not currently meant to support a high traffic website, I got rid of the separate staging environment that had its own cloud infrastructure.

I also ditched Cloudflare as a provider. Their service does make https easy, but it also makes it too easy. Traffic is plain text from Cloudflare (inclusive) to the compute instance web server. Even though it's unlikely any user would ever care, I've got personal issues with that approach. So to provide encryption of traffic to the compute instance itself, I used the SWAG docker image from the gang over at linuxserver.io and made this a multi-container docker compose project meant to run on one compute instance.

Cloud load balancers are meant to be the "proper" solution to this problem, but they are expensive for a hobby project.
