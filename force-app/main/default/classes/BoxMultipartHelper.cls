public class BoxMultipartHelper {

    public static Blob buildMultipartBody(
        String folderId,
        String fileName,
        Blob fileBlob,
        String boundary
    ){

        String attributes =
        '{"name":"' + fileName + '","parent":{"id":"' + folderId + '"}}';

        String bodyStart =
        '--' + boundary + '\r\n' +
        'Content-Disposition: form-data; name="attributes"\r\n' +
        'Content-Type: application/json\r\n\r\n' +
        attributes + '\r\n' +

        '--' + boundary + '\r\n' +
        'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
        'Content-Type: application/octet-stream\r\n\r\n';

        String bodyEnd =
        '\r\n--' + boundary + '--\r\n';

        Blob startBlob = Blob.valueOf(bodyStart);
        Blob endBlob = Blob.valueOf(bodyEnd);

        String base64Start = EncodingUtil.base64Encode(startBlob);
        String base64File  = EncodingUtil.base64Encode(fileBlob);
        String base64End   = EncodingUtil.base64Encode(endBlob);

        if(base64File.endsWith('==')){
            base64File = base64File.substring(0, base64File.length()-2) + '0K';
        } 
        else if(base64File.endsWith('=')){
            base64File = base64File.substring(0, base64File.length()-1) + 'N';
        }

        Blob finalBody = EncodingUtil.base64Decode(
            base64Start + base64File + base64End
        );

        return finalBody;
    }
}