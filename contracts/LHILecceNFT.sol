// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LHILecceNFT is ERC1155URIStorage, ERC2981, Ownable {
    using SafeERC20 for IERC20;
    string public name = "LHI Lecce NFT";
    string public symbol = "LHILE";
    string public previewCID = "Qm..."; // CID del file preview generico

    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalMinted;
    mapping(uint256 => uint256) public pricesInWei; // Prezzi in wei
    mapping(uint256 => bool) public isValidTokenId; // Per controllare i tokenId validi
    mapping(uint256 => string) private encryptedURIs; // Mappa tokenId agli URI crittografati
    mapping(uint256 => string) private tokenCIDs; // Mappa tokenId ai CIDs

    address public withdrawWallet;
    IERC20 public paymentToken;

    struct BurnRequest {
        address requester;
        uint256 tokenId;
        uint256 quantity;
        bool approved;
    }

    BurnRequest[] public burnRequests;

    uint256 public constant MINIMUM_TOTAL_VALUE = 6_000_000 ether; // 6 milioni di euro in wei

    struct RoyaltyRange {
        uint256 minId;
        uint256 maxId;
        uint96 feeNumerator; // in base 10000
    }
    RoyaltyRange[] public royaltyRanges;

    event NFTMinted(address indexed buyer, uint256 tokenId, uint256 quantity, uint256 price, string encryptedURI);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event BaseURIUpdated(string newBaseURI);
    event NFTBurned(address indexed owner, uint256 tokenId, uint256 quantity);
    event BurnRequested(address indexed requester, uint256 tokenId, uint256 quantity, uint256 requestId);
    event BurnApproved(uint256 requestId, address indexed requester, uint256 tokenId, uint256 quantity);
    event BurnDenied(uint256 requestId, address indexed requester, uint256 tokenId, uint256 quantity);

    constructor(string memory _baseURI, address _owner, address _paymentToken)
        ERC1155(_baseURI)
        Ownable(_owner)
    {
        require(bytes(_baseURI).length > 0, "Base URI cannot be empty");
        withdrawWallet = _owner;
        paymentToken = IERC20(_paymentToken);

        // Imposta la royalty di default (es. 5% a favore dell'owner)
        _setDefaultRoyalty(_owner, 500); // 500 = 5% (in base 10000)

        // Definisci prezzi, maxSupply e tokenId validi in un unico ciclo
        uint256[24] memory percent = [
            uint256(1), uint256(2), uint256(3), uint256(4), uint256(5), uint256(10), uint256(15), uint256(20),
            uint256(25), uint256(30), uint256(35), uint256(40), uint256(45), uint256(50), uint256(55), uint256(60),
            uint256(65), uint256(70), uint256(75), uint256(80), uint256(85), uint256(90), uint256(95), uint256(100)
        ];
        for (uint256 i = 1; i <= 24; i++) {
            pricesInWei[i] = (percent[i-1] * 1e18) / 100; // 1e18 = 1 unità (ETH/WETH/MATIC)
            maxSupply[i] = 50000;
            isValidTokenId[i] = true;
        }

        // Inizializza gli URI crittografati
        encryptedURIs[1] = "bafybeibcdd7xkcnysru7z4kianttaykhhrl5zewizngzuw2m7ij6atzunq";
        encryptedURIs[2] = "bafybeicwotpc5l2v6uhbdxyyyjm57asclfekez2g5j7bbkisx5rfcjb6ta";
        encryptedURIs[3] = "bafybeigbxjmng64ztva7nc5sfkwebvxajv2qjv6s4222p3mqu6ulxk4twi";
        encryptedURIs[4] = "bafybeicpsoa63f4mvj6tffo3iyaeq6zfyocgieidtzao3hkgcjyctpve5u";
        encryptedURIs[5] = "bafybeiekmmfdut2begk6orihy2i7czigvgl7tz52aqpevz77ffnmzcmsii";
        encryptedURIs[6] = "bafybeihthtbusz5krrwal6ikyilhno3xowkjnqnx7svkha5kmci3me43fm";
        encryptedURIs[7] = "bafybeie3djtgvjvqg5gg2ngawj2h2wnoxzkx7ndi2amppqmzgpfipzbubi";
        encryptedURIs[8] = "bafybeifdheepywqg4jt6tg4n36dltu2yvvunog472gz63n6qktihqkd5uq";
        encryptedURIs[9] = "bafybeidro46zjdvtvabedg7vkzbbsqazztey24indvyhxw476a4eajamca";
        encryptedURIs[10] = "bafybeifopjtpis5z5nmpiojdojpsr67n3q6oyehcwft5mv3bjideli2eli";
        encryptedURIs[11] = "bafybeifv4lv752infxvwimz6dab5cm5p6qnaykqqv6hbhadhyv3ocoyzga";
        encryptedURIs[12] = "bafybeih7f5ud2ogbnldlanvt2zldgi2f45ttptka6qxi2stpzxy5u2mz5a";
        encryptedURIs[13] = "bafybeiajdlk3ggb4zeavnj3bd5fiewe7weyzf6ypxycs4niw2yengbezhu";
        encryptedURIs[14] = "bafybeifjvku5x2xajhx77cwbpkefgquztwse2kynjcnrkl32eaactxn4ta";
        encryptedURIs[15] = "bafybeielptqraatqmzmhzewndanf5u445cqr56vtxphoa2vinf7ou24yoe";
        encryptedURIs[16] = "bafybeigsbban76tpciuf3yukjrgtjrc7wwrjf3w42ssgybtputzwmybuyq";
        encryptedURIs[17] = "bafybeigzb6hv6jqgiirbdtxtjmpio7p6d6mbtorvoi3zgisyny6gcznpo4";
        encryptedURIs[18] = "bafybeignmui522fqu3x74m3di4qxisll6jn63piiucod72q7ridfoetna4";
        encryptedURIs[19] = "bafybeibzrtl5kpqwrnie52ktczdg55zm44rcebyu2tk3jzxod42ughbu5q";
        encryptedURIs[20] = "bafybeid35sdnjt4n3ko6axlknhjmfojhtgag6hqabijuqtmzzf26gnfdci";
        encryptedURIs[21] = "bafybeia4v7mnjhvsk4bchkdcclq7rl2jont7bmuyb5wrvrqi5sbshua5ge";
        encryptedURIs[22] = "bafybeifmwyc4ucgh5fbqlxgup5evkzk3kv7tes65vdjixtnnl2lwgkrobi";
        encryptedURIs[23] = "bafybeicgz6ztjlnzp5eet4tze74ck5x7hzumz2qfm2sc5tx6tmzhb6nu64";
        encryptedURIs[24] = "bafybeihooyvtk7fka5bfh5biqusufanljc6ngxx4vvehksq5halovui3n4";

        // Imposta le fasce di royalty iniziali
        royaltyRanges.push(RoyaltyRange(1, 15, 100));   // 1% per tokenId 1-15
        royaltyRanges.push(RoyaltyRange(16, 24, 500));  // 5% per tokenId 16-24
        royaltyRanges.push(RoyaltyRange(25, 50, 600));  // 6% per tokenId 25-50
    }

    // Override richiesto da Solidity per ERC1155 + ERC2981
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Override della funzione royaltyInfo per regole personalizzate e modificabili
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view override returns (address, uint256) {
        uint96 feeNumerator = 0;
        for (uint256 i = 0; i < royaltyRanges.length; i++) {
            if (tokenId >= royaltyRanges[i].minId && tokenId <= royaltyRanges[i].maxId) {
                feeNumerator = royaltyRanges[i].feeNumerator;
                break;
            }
        }
        uint256 royaltyAmount = (salePrice * feeNumerator) / _feeDenominator();
        return (royaltyRecipient(), royaltyAmount);
    }

    function royaltyRecipient() public view returns (address) {
        return owner();
    }

    // (Opzionale) Funzione per cambiare la royalty
    function setRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Funzione per aggiornare le fasce di royalty (soloOwner)
    function setRoyaltyRange(uint256 index, uint256 minId, uint256 maxId, uint96 feeNumerator) external onlyOwner {
        require(index < royaltyRanges.length, "Invalid index");
        royaltyRanges[index] = RoyaltyRange(minId, maxId, feeNumerator);
    }

    function addRoyaltyRange(uint256 minId, uint256 maxId, uint96 feeNumerator) external onlyOwner {
        royaltyRanges.push(RoyaltyRange(minId, maxId, feeNumerator));
    }

    function mintNFT(uint256 tokenId, uint256 quantity, bool payWithToken) external payable {
        require(isValidTokenId[tokenId], "Invalid tokenId");
        require(totalMinted[tokenId] + quantity <= maxSupply[tokenId], "Exceeds max supply");
        require(quantity > 0, "Invalid quantity");

        uint256 totalCostInWei = pricesInWei[tokenId] * quantity;

        if (payWithToken) {
            paymentToken.safeTransferFrom(msg.sender, address(this), totalCostInWei);
        } else {
            // Pagamento con valuta nativa (MATIC su Polygon, ETH su Ethereum)
            require(msg.value == totalCostInWei, "Incorrect native amount");
        }

        totalMinted[tokenId] += quantity;
        _mint(msg.sender, tokenId, quantity, "");
        emit NFTMinted(msg.sender, tokenId, quantity, pricesInWei[tokenId], encryptedURIs[tokenId]);
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        paymentToken.safeTransfer(withdrawWallet, balance);
        emit FundsWithdrawn(withdrawWallet, balance);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!isValidTokenId[tokenId] || bytes(tokenCIDs[tokenId]).length == 0) {
            return string(abi.encodePacked("ipfs://", previewCID));
        }
        return string(abi.encodePacked("ipfs://", tokenCIDs[tokenId]));
    }

    function getEncryptedURI(uint256 tokenId) external view returns (string memory) {
        require(isValidTokenId[tokenId], "Invalid tokenId");
        return encryptedURIs[tokenId];
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        payable(withdrawWallet).transfer(balance);
        emit FundsWithdrawn(withdrawWallet, balance);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _setURI(newBaseURI);
        emit BaseURIUpdated(newBaseURI);
    }

    function setTokenCID(uint256 tokenId, string memory cid) external onlyOwner {
        require(isValidTokenId[tokenId], "Invalid tokenId");
        tokenCIDs[tokenId] = cid;
    }

    function requestBurn(uint256 tokenId, uint256 quantity) external {
        require(isValidTokenId[tokenId], "Invalid tokenId");
        require(balanceOf(msg.sender, tokenId) >= quantity, "Insufficient balance");

        burnRequests.push(BurnRequest({
            requester: msg.sender,
            tokenId: tokenId,
            quantity: quantity,
            approved: false
        }));

        uint256 requestId = burnRequests.length - 1;
        emit BurnRequested(msg.sender, tokenId, quantity, requestId);
    }

    function approveBurn(uint256 requestId, bool approve) external onlyOwner {
        require(requestId < burnRequests.length, "Invalid requestId");
        BurnRequest storage request = burnRequests[requestId];
        require(!request.approved, "Request already processed");

        if (approve) {
            uint256 totalValueAfterBurn = calculateTotalValueAfterBurn(request.tokenId, request.quantity);
            require(totalValueAfterBurn >= MINIMUM_TOTAL_VALUE, "Cannot burn below minimum total value");

            _burn(request.requester, request.tokenId, request.quantity);
            totalMinted[request.tokenId] -= request.quantity;
            request.approved = true;

            emit BurnApproved(requestId, request.requester, request.tokenId, request.quantity);
        } else {
            emit BurnDenied(requestId, request.requester, request.tokenId, request.quantity);
        }
    }

    function calculateTotalValueAfterBurn(uint256 tokenId, uint256 quantity) public view returns (uint256) {
        uint256 totalValue = 0;

        uint256[] memory mintedTokens = new uint256[](24);
        for (uint256 i = 1; i <= 24; i++) {
            mintedTokens[i - 1] = totalMinted[i];
        }

        mintedTokens[tokenId - 1] -= quantity; // Sottrai la quantità che si vuole bruciare

        for (uint256 i = 0; i < 24; i++) {
            totalValue += mintedTokens[i] * pricesInWei[i + 1];
        }

        return totalValue;
    }

    function onlyOwnerFunction() external view {
        require(msg.sender == owner(), "Ownable: caller is not the owner");
    }
}
