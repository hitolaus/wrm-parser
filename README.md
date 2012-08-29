wrm-parser
==========

Extracts and parses the WRM header data from ASF 1.0 files.

The WRM header format:

```xml
<WRMHEADER version="2.0.0.0">
	<DATA>
		<SECURITYVERSION>2.2</SECURITYVERSION>
		<CID>WMID:246083143</CID>
		<LAINFO>http://...</LAINFO>
		<KID>...</KID>
		<CHECKSUM>...</CHECKSUM>
	</DATA>
	<SIGNATURE>
		<HASHALGORITHM type="SHA"></HASHALGORITHM>
		<SIGNALGORITHM type="MSDRM"></SIGNALGORITHM>
		<VALUE>...</VALUE>
	</SIGNATURE>
</WRMHEADER>
```