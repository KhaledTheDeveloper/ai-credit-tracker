# Disclaimer

## Non-Affiliation Notice

**AI Credit Tracker** is an independent, community-driven open-source project. It is:

- **NOT** affiliated with Google LLC, Alphabet Inc., or any of their subsidiaries.
- **NOT** affiliated with Anthropic PBC.
- **NOT** sponsored, endorsed, or approved by any of the above organizations.
- **NOT** an official product of any company.

## Trademark Acknowledgments

The following trademarks are the property of their respective owners and are used here solely for **descriptive purposes** to indicate compatibility:

- **Google**, **Gmail**, **Google Cloud**, **Gemini**, and **Google AI Pro** are registered trademarks of **Google LLC**.
- **Claude** is a registered trademark of **Anthropic PBC**.
- **GPT** is a registered trademark of **OpenAI, Inc.**

Use of these names in this project does not imply any affiliation with, endorsement by, or sponsorship from the trademark holders.

## API Notice

> ⚠️ **Important**: This tool queries an internal Google API endpoint (`v1internal:retrieveUserQuotaSummary`) that is **not** part of the public Google Cloud API surface. This endpoint is intended for Google's own first-party applications and may change, be restricted, or be discontinued at any time without notice.

### What this means for you:

1. **Use at your own risk.** The authors of this project make no guarantees about the continued availability or stability of this API endpoint.
2. **No warranty.** This tool is provided "AS IS" without warranty of any kind. See the [MIT License](LICENSE) for the full warranty disclaimer.
3. **Potential account impact.** While this tool is strictly read-only and uses only your own credentials, using unofficial API endpoints could theoretically impact your Google account access. The authors assume no liability for any such consequences.
4. **Educational and personal use.** This tool is intended for personal productivity and educational purposes only.

## Rate Limiting & Respectful Usage

AI Credit Tracker is designed to be a responsible API consumer:

- **Default polling interval**: 15 minutes (configurable, minimum enforced)
- **Exponential backoff**: On errors, the polling interval automatically doubles (up to 3 retries)
- **Random jitter**: 0–3 seconds of random delay added to each poll to avoid thundering herd
- **Read-only**: This tool only reads quota information. It never creates, modifies, or deletes any data.

## Limitation of Liability

TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL THE AUTHORS, COPYRIGHT HOLDERS, OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
