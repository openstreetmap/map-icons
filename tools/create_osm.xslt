<?xml version="1.0" encoding="iso-8859-1"?>
<!-- for details, please have a look at the corresponding .sh file -->
<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="html"
>
 
    <xsl:output
        method="text"
        doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
        doctype-public="-//W3C//DTD XHTML 1.1//EN"
    />
 
    <xsl:template match="rules">
# automatically generated script, do not edit!
		<xsl:for-each select="rule">
			<xsl:for-each select="icon">
mkdir --parents <xsl:value-of select = "$dest_dir" />/<xsl:value-of select="../condition/@k" />
cp <xsl:value-of select = "$src_dir" />/<xsl:value-of select="@src" /> <xsl:text disable-output-escaping="yes"> </xsl:text> <xsl:value-of select = "$dest_dir" />/<xsl:value-of select="../condition/@k" />/<xsl:value-of select="../condition/@v" />.png
			</xsl:for-each>
		</xsl:for-each>
    </xsl:template>
 
</xsl:stylesheet>
