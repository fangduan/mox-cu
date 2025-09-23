import base64
from src import mood_nft


def deploy_mood():
    happy_svg_uri_ = ""
    sad_svg_uri_ = ""
    with open("./images/happy.svg") as f:
        happy_svg = f.read()
        happy_svg_uri_ = save_to_base64_uri(happy_svg)
    with open("./images/sad.svg") as f:
        sad_svg = f.read()
        sad_svg_uri_ = save_to_base64_uri(sad_svg)

    contract = mood_nft.deploy(happy_svg_uri_, sad_svg_uri_)
    contract.mint_nft()
    print(contract.tokenURI(0))
    return contract


def moccasin_main():
    deploy_mood()


def save_to_base64_uri(svg):
    svg_bytes = svg.encode("utf-8")
    b64_bytes = base64.b64encode(svg_bytes).decode("utf-8")
    return f"data:image/svg+xml;base64, {b64_bytes}"
