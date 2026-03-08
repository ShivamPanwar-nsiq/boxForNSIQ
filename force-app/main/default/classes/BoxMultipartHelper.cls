public class BoxMultipartHelper {

    /*
    ============================================================
    BUILD MULTIPART REQUEST BODY
    ============================================================
    This matches exactly how Postman sends multipart/form-data
    ============================================================
    */

    public static Blob buildMultipartBody(
        String folderId,
        String fileName,
        Blob fileBlob,
        String boundary
    ){

        System.debug('Building Multipart Body');

        String attributes =
        '{"name":"' + fileName + '","parent":{"id":"' + folderId + '"}}';

        String part1 =
        '--' + boundary + '\r\n' +
        'Content-Disposition: form-data; name="attributes"\r\n' +
        'Content-Type: application/json\r\n\r\n' +
        attributes + '\r\n';

        String part2 =
        '--' + boundary + '\r\n' +
        'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
        'Content-Type: application/octet-stream\r\n\r\n';

        String closing =
        '\r\n--' + boundary + '--';

        Blob body = Blob.valueOf(part1);

        body = concat(body, Blob.valueOf(part2));
        body = concat(body, fileBlob);
        body = concat(body, Blob.valueOf(closing));

        return body;
    }


    /*
    ============================================================
    BLOB CONCAT HELPER
    ============================================================
    Used to combine multiple blob parts
    ============================================================
    */

    public static Blob concat(Blob a, Blob b){

        if(a == null) return b;
        if(b == null) return a;

        String hex =
        EncodingUtil.convertToHex(a) +
        EncodingUtil.convertToHex(b);

        return EncodingUtil.convertFromHex(hex);
    }
}